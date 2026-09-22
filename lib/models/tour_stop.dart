import 'poi.dart';

/// Ein einzelner Stopp innerhalb einer geplanten Rundtour (PROJECT_BRAIN
/// Abschnitt 23, Erweiterung 2 - "automatische Rundtour", vorgezogen und
/// mit dem Nutzer als regelbasierter Greedy-Algorithmus abgestimmt).
///
/// Wie bei [Poi]-Empfehlungen (siehe Recommendation/ContextEngine) sind
/// Distanz/Zeit nur grobe Schaetzungen (Luftlinie, Durchschnitts-
/// geschwindigkeit) zur Tourplanung - die tatsaechliche Route je Etappe
/// wird erst beim Start der Tour ueber Valhalla berechnet
/// (TourRouteResult/RoutingService).
class TourStop {
  const TourStop({
    required this.poi,
    required this.legDistanceMeters,
    required this.legTravelTimeSeconds,
    required this.cumulativeTimeSeconds,
    required this.reason,
  });

  final Poi poi;

  /// Geschaetzte Distanz vom vorherigen Punkt (Tourstart oder vorheriger
  /// Stopp) zu diesem Stopp.
  final double legDistanceMeters;

  /// Geschaetzte Reisezeit fuer dieselbe Etappe.
  final double legTravelTimeSeconds;

  /// Kumulierte Reisezeit ab Tourstart bis inklusive dieses Stopps (ohne
  /// Rueckweg zum Start).
  final double cumulativeTimeSeconds;

  /// Kurze Begruendung, warum dieser Stopp gewaehlt wurde (aus der
  /// Context-Engine-Bewertung an dieser Stelle der Tour).
  final String reason;
}

/// Ergebnis der Tourplanung: die gewaehlten Stopps in Besuchsreihenfolge
/// plus die geschaetzte Rueckstrecke zum urspruenglichen Startpunkt (die
/// Rundtour soll mit dem Nutzer abgestimmt immer zum Start zurueckfuehren).
class TourResult {
  const TourResult({
    required this.stops,
    required this.returnLegDistanceMeters,
    required this.returnLegTravelTimeSeconds,
  });

  final List<TourStop> stops;

  final double returnLegDistanceMeters;
  final double returnLegTravelTimeSeconds;

  /// Gesamte geschaetzte Reisezeit inkl. Rueckweg (ohne Aufenthaltszeit an
  /// den Stopps - die App kennt keine Besuchsdauer je POI).
  double get totalTravelTimeSeconds =>
      (stops.isEmpty ? 0.0 : stops.last.cumulativeTimeSeconds) +
      returnLegTravelTimeSeconds;

  double get totalDistanceMeters =>
      stops.fold(0.0, (sum, stop) => sum + stop.legDistanceMeters) +
      returnLegDistanceMeters;
}
