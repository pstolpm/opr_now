import 'package:geolocator/geolocator.dart';

import '../models/poi.dart';
import '../models/recommendation.dart';
import '../models/user_position.dart';
import '../models/weather_context.dart';

/// Regelbasierte, transparente Bewertung von POIs anhand des aktuellen
/// Kontexts (Standort, Zeitbudget, Fortbewegungsart, Interessen, Wetter).
///
/// Bewusst **kein** Machine Learning (PROJECT_BRAIN Abschnitt 6: "Es ist
/// nicht notwendig, Machine Learning einzusetzen. Eine nachvollziehbare
/// Entscheidungslogik ist fuer das Uni-Projekt fachlich sinnvoller.").
///
/// Die hier berechnete Reisezeit ist nur eine grobe Schaetzung anhand einer
/// angenommenen Durchschnittsgeschwindigkeit - sie dient der Auswahl und
/// Sortierung. Die tatsaechliche Route (inkl. Wegenetz) wird erst danach,
/// fuer den vom Nutzer gewaehlten POI, ueber Valhalla berechnet
/// (RoutingService/PoiDetailScreen).
class ContextEngine {
  const ContextEngine();

  /// Angenommene Durchschnittsgeschwindigkeiten fuer die Zeitschaetzung.
  /// Grobe Richtwerte inkl. kleinerer Pausen/Umwege, keine exakte
  /// Routing-Geschwindigkeit.
  static const _walkingSpeedMetersPerSecond = 1.25; // ~ 4,5 km/h
  static const _cyclingSpeedMetersPerSecond = 4.17; // ~ 15 km/h

  /// Distanz, ab der [_distanceScore] auf 0 sinkt (Skalierungsgrenze,
  /// keine harte Ausschlussgrenze - der Zeitbudget-Filter uebernimmt das
  /// tatsaechliche Ausschliessen zu weit entfernter POIs).
  static const _maxRelevantDistanceMeters = 25000;

  /// Kategorien, die ueberwiegend im Freien liegen und daher bei schlechtem
  /// Wetter abgewertet werden (PROJECT_BRAIN Abschnitt 6, Beispielregeln).
  static const _outdoorCategories = {'natur', 'badestelle'};

  /// Kategorien, die ueberwiegend drinnen besucht werden (Museen,
  /// historische Innenraeume o. Ae.) und daher bei schlechtem Wetter
  /// aufgewertet werden. Unsere Kategorie 'sehenswuerdigkeit' fasst OSM-
  /// tourism/historic-Tags zusammen und enthaelt sowohl drinnen als auch
  /// draussen liegende Ziele - vereinfachend als eher "drinnen" behandelt,
  /// siehe PROJECT_BRAIN Abschnitt 48 ("endgueltige POI-Kategorien" offen).
  static const _indoorCategories = {'sehenswuerdigkeit'};

  /// Berechnet und sortiert Empfehlungen fuer [pois] anhand des Kontexts.
  ///
  /// POIs, deren geschaetzte Hin- und Rueckreisezeit das [timeBudget]
  /// ueberschreitet, werden ausgeschlossen (PROJECT_BRAIN Abschnitt 6).
  /// Das Ergebnis ist absteigend nach Recommendation.overallScore
  /// sortiert.
  List<Recommendation> recommend({
    required List<Poi> pois,
    required UserPosition position,
    required Duration timeBudget,
    required String mobility,
    required Set<String> interests,
    WeatherContext? weather,
  }) {
    final speed = mobility == 'bicycle'
        ? _cyclingSpeedMetersPerSecond
        : _walkingSpeedMetersPerSecond;

    final results = <Recommendation>[];
    for (final poi in pois) {
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        poi.latitude,
        poi.longitude,
      );
      final oneWaySeconds = distanceMeters / speed;
      final roundTripSeconds = oneWaySeconds * 2;

      // Regel: Hin- und Rueckreisezeit > Zeitbudget -> POI ausschliessen.
      if (roundTripSeconds > timeBudget.inSeconds) {
        continue;
      }

      final distanceScore = _distanceScore(distanceMeters);
      final interestScore = _interestScore(poi, interests);
      final weatherScore = _weatherScore(poi, weather);
      final contextScore = _contextScore(poi);

      final overallScore = 0.40 * distanceScore +
          0.30 * interestScore +
          0.20 * weatherScore +
          0.10 * contextScore;

      results.add(
        Recommendation(
          poi: poi,
          distanceMeters: distanceMeters,
          travelTimeSeconds: oneWaySeconds,
          overallScore: overallScore,
          distanceScore: distanceScore,
          interestScore: interestScore,
          weatherScore: weatherScore,
          contextScore: contextScore,
          reason: _buildReason(
            poi: poi,
            distanceMeters: distanceMeters,
            interestScore: interestScore,
            weatherScore: weatherScore,
            weather: weather,
          ),
        ),
      );
    }

    results.sort((a, b) => b.overallScore.compareTo(a.overallScore));
    return results;
  }

  /// 1.0 = ganz nah, 0.0 = an oder jenseits von
  /// [_maxRelevantDistanceMeters]. Lineare Abnahme - fuer den MVP bewusst
  /// einfach gehalten (PROJECT_BRAIN Regel 6: nachvollziehbar).
  double _distanceScore(double distanceMeters) {
    final score = 1 - (distanceMeters / _maxRelevantDistanceMeters);
    return score.clamp(0.0, 1.0);
  }

  /// Ohne Interessenauswahl ("alle") bekommt jede Kategorie einen
  /// neutralen Score. Mit Auswahl werden passende Kategorien deutlich
  /// bevorzugt (PROJECT_BRAIN Abschnitt 6, Beispielregel).
  double _interestScore(Poi poi, Set<String> interests) {
    if (interests.isEmpty) return 0.6;
    return interests.contains(poi.category) ? 1.0 : 0.2;
  }

  /// Wetterbasierte Auf-/Abwertung nach den Beispielregeln aus
  /// PROJECT_BRAIN Abschnitt 6 ("Outdoor + Regen -> abwerten",
  /// "Museum/drinnen + schlechtes Wetter -> aufwerten"). Ohne Wetterdaten
  /// (z. B. Open-Meteo nicht erreichbar) neutraler Score, damit ein
  /// API-Ausfall POIs nicht grundlos ausschliesst (PROJECT_BRAIN Regel 8).
  double _weatherScore(Poi poi, WeatherContext? weather) {
    if (weather == null) return 0.7;

    // "Schlechtes Wetter": spuerbarer Niederschlag oder ein WMO-Code fuer
    // Regen/Schauer/Schnee/Gewitter (>= 61, siehe Open-Meteo-Doku).
    final badWeather = weather.precipitation > 1.0 || weather.weatherCode >= 61;
    final isOutdoor = _outdoorCategories.contains(poi.category);
    final isIndoor = _indoorCategories.contains(poi.category);

    if (badWeather) {
      if (isOutdoor) return 0.2;
      if (isIndoor) return 0.9;
      return 0.6; // Gastronomie/Sonstiges: gemischt drinnen/draussen
    }

    // Gutes Wetter.
    if (poi.category == 'badestelle' && weather.temperature >= 20) {
      return 1.0; // warmes, trockenes Wetter passt besonders gut zum Baden
    }
    if (isOutdoor) return 0.9;
    if (isIndoor) return 0.6;
    return 0.7;
  }

  /// "Weiterer Kontext"-Anteil (10 %, PROJECT_BRAIN Abschnitt 6). Fuer den
  /// MVP bewusst einfach: POIs mit zusaetzlichen Detailinformationen (z. B.
  /// amtliche Badestellen-Details oder eine Beschreibung) gelten als
  /// besser fuer eine fundierte Empfehlung geeignet als POIs ganz ohne
  /// Zusatzinfos. Kann spaeter um Tageszeit, Oeffnungszeiten o. Ae.
  /// erweitert werden (PROJECT_BRAIN Abschnitt 48).
  double _contextScore(Poi poi) {
    final hasDetails = poi.details != null && poi.details!.isNotEmpty;
    final hasDescription = poi.description != null && poi.description!.isNotEmpty;
    return (hasDetails || hasDescription) ? 1.0 : 0.6;
  }

  String _buildReason({
    required Poi poi,
    required double distanceMeters,
    required double interestScore,
    required double weatherScore,
    required WeatherContext? weather,
  }) {
    final parts = <String>[];
    final km = (distanceMeters / 1000).toStringAsFixed(1);
    parts.add('$km km entfernt');

    if (interestScore >= 1.0) {
      parts.add('passt zu deinen Interessen');
    }

    if (weather != null) {
      if (weatherScore >= 0.9) {
        parts.add('gut geeignet bei aktuellem Wetter');
      } else if (weatherScore <= 0.2) {
        parts.add('bei aktuellem Wetter weniger geeignet');
      }
    }

    return parts.join(' + ');
  }
}
