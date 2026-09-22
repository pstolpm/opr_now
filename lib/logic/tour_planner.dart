import 'package:geolocator/geolocator.dart';

import '../models/poi.dart';
import '../models/tour_stop.dart';
import '../models/user_position.dart';
import '../models/weather_context.dart';
import 'context_engine.dart';

/// Regelbasierte Planung einer Rundtour mit mehreren Stopps
/// (PROJECT_BRAIN Abschnitt 23, Erweiterung 2 - mit dem Nutzer
/// vorgezogen, aber ausdruecklich **kein** Machine Learning, siehe
/// [ContextEngine]).
///
/// Einfacher Greedy-Algorithmus:
///
/// 1. Von der aktuellen Position aus (zunaechst der Tourstart, danach der
///    zuletzt gewaehlte Stopp) wird ueber [ContextEngine] der
///    bestbewertete, noch nicht besuchte POI ermittelt.
/// 2. Der bestbewertete POI wird nur uebernommen, wenn die bisherige
///    Reisezeit + Etappe dorthin + geschaetzter Rueckweg von dort zum
///    urspruenglichen Tourstart weiterhin ins Zeitbudget passt. Falls
///    nicht, wird der naechstbeste POI geprueft usw.
/// 3. Wiederholen, bis entweder die maximale Stoppzahl erreicht ist, kein
///    POI mehr passt, oder keine POIs mehr uebrig sind.
///
/// Zusaetzliche Regel (mit dem Nutzer abgestimmt): Badestellen sind auf
///    Fuss-/Radtouren nicht beliebig wiederholbar (man badet nicht an
///    mehreren Stellen hintereinander) - pro Rundtour wird daher
///    hoechstens eine Badestelle eingeplant, alle anderen Kategorien
///    duerfen weiterhin mehrfach vorkommen.
///
/// Kein exaktes Tourenplanungsproblem (TSP) - fuer ein Studienprojekt
/// bewusst einfach und nachvollziehbar gehalten (PROJECT_BRAIN Regel 6).
/// Alle Distanzen/Zeiten sind wie bei der ContextEngine nur grobe
/// Schaetzungen (Luftlinie, Durchschnittsgeschwindigkeit) zur Auswahl -
/// die tatsaechliche Route je Etappe wird erst beim Start der Tour ueber
/// Valhalla berechnet (siehe TourRouteResult).
class TourPlanner {
  const TourPlanner({this.contextEngine = const ContextEngine()});

  final ContextEngine contextEngine;

  /// Mit dem Nutzer abgestimmte Standard-Obergrenze fuer die Anzahl
  /// Stopps pro Rundtour.
  static const defaultMaxStops = 4;

  /// Sehr grosszuegiges Budget fuer den internen ContextEngine-Aufruf:
  /// die ContextEngine schliesst POIs bereits selbst aus, wenn deren
  /// Hin- UND Rueckweg (zur *aktuellen* Position) das uebergebene Budget
  /// sprengt. Das waere hier zu streng, weil wir nur die Etappe *hin*
  /// brauchen und den Rueckweg separat gegen den echten Tourstart pruefen
  /// (siehe [plan]). Daher hier bewusst (praktisch) kein Limit.
  static const _noExclusionBudget = Duration(days: 1);

  /// Kategorie-Bezeichner fuer Badestellen (siehe [Poi.category]).
  static const _badestelleCategory = 'badestelle';

  TourResult plan({
    required List<Poi> pois,
    required UserPosition start,
    required Duration timeBudget,
    required String mobility,
    required Set<String> interests,
    WeatherContext? weather,
    int maxStops = defaultMaxStops,
  }) {
    final speed = mobility == 'bicycle'
        ? ContextEngine.cyclingSpeedMetersPerSecond
        : ContextEngine.walkingSpeedMetersPerSecond;

    final remainingPois = List<Poi>.of(pois);
    final stops = <TourStop>[];

    var currentLat = start.latitude;
    var currentLng = start.longitude;
    var elapsedSeconds = 0.0;
    var badestelleChosen = false;

    while (stops.length < maxStops && remainingPois.isNotEmpty) {
      final budgetLeft = timeBudget.inSeconds - elapsedSeconds;
      if (budgetLeft <= 0) break;

      final currentPosition = UserPosition(
        latitude: currentLat,
        longitude: currentLng,
        timestamp: start.timestamp,
        source: start.source,
      );

      // Nach Score sortierte Kandidaten ab der aktuellen Position -
      // Auswahl unter den Kandidaten erfolgt unten anhand des echten
      // Rueckwegs zum Tourstart.
      final candidates = contextEngine.recommend(
        pois: remainingPois,
        position: currentPosition,
        timeBudget: _noExclusionBudget,
        mobility: mobility,
        interests: interests,
        weather: weather,
      );

      Poi? chosenPoi;
      double chosenLegSeconds = 0;
      String chosenReason = '';

      for (final candidate in candidates) {
        if (badestelleChosen &&
            candidate.poi.category == _badestelleCategory) {
          continue; // max. eine Badestelle pro Rundtour
        }
        final legSeconds = candidate.travelTimeSeconds;
        final returnDistance = Geolocator.distanceBetween(
          candidate.poi.latitude,
          candidate.poi.longitude,
          start.latitude,
          start.longitude,
        );
        final returnSeconds = returnDistance / speed;

        if (elapsedSeconds + legSeconds + returnSeconds <=
            timeBudget.inSeconds) {
          chosenPoi = candidate.poi;
          chosenLegSeconds = legSeconds;
          chosenReason = candidate.reason;
          break;
        }
      }

      if (chosenPoi == null) break; // kein weiterer Stopp passt mehr ins Budget

      final legDistance = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        chosenPoi.latitude,
        chosenPoi.longitude,
      );
      elapsedSeconds += chosenLegSeconds;

      stops.add(
        TourStop(
          poi: chosenPoi,
          legDistanceMeters: legDistance,
          legTravelTimeSeconds: chosenLegSeconds,
          cumulativeTimeSeconds: elapsedSeconds,
          reason: chosenReason,
        ),
      );

      if (chosenPoi.category == _badestelleCategory) {
        badestelleChosen = true;
      }
      remainingPois.removeWhere((p) => p.id == chosenPoi!.id);
      currentLat = chosenPoi.latitude;
      currentLng = chosenPoi.longitude;
    }

    final returnDistance = stops.isEmpty
        ? 0.0
        : Geolocator.distanceBetween(
            currentLat,
            currentLng,
            start.latitude,
            start.longitude,
          );

    return TourResult(
      stops: stops,
      returnLegDistanceMeters: returnDistance,
      returnLegTravelTimeSeconds: returnDistance / speed,
    );
  }
}
