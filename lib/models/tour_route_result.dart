import 'route_result.dart';

/// Ergebnis der tatsaechlichen Routenberechnung fuer eine Rundtour:
/// mehrere nacheinander ueber Valhalla berechnete Etappen
/// (Start -> Stopp 1 -> Stopp 2 -> ... -> zurueck zum Start).
///
/// Wird analog zu [RouteResult] von der DiscoverScreen an den MapScreen
/// zurueckgegeben, sobald der Nutzer eine geplante Rundtour tatsaechlich
/// startet (PROJECT_BRAIN Abschnitt 23, vorgezogene Rundtour-Funktion).
class TourRouteResult {
  const TourRouteResult({required this.legs, required this.stopNames});

  /// Eine [RouteResult] pro Etappe, in Besuchsreihenfolge. Die letzte
  /// Etappe ist immer der Rueckweg zum urspruenglichen Startpunkt.
  final List<RouteResult> legs;

  /// Namen der Stopps in Besuchsreihenfolge (ohne den abschliessenden
  /// Rueckweg) - fuer Geofence-Meldungen im MapScreen ("Ziel X erreicht,
  /// weiter zu Y").
  final List<String> stopNames;
}
