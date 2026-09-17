import 'package:maplibre_gl/maplibre_gl.dart';

/// Zentrale Karten-Konstanten für OPR NOW.
///
/// Alle Koordinaten sind WGS84 (EPSG:4326). MapLibre erwartet in `LatLng`
/// die Reihenfolge (Breite, Länge) - anders als GeoJSON, das
/// (Länge, Breite) verwendet. Siehe PROJECT_BRAIN Abschnitt 34.
class MapConstants {
  MapConstants._();

  /// Vektorkarten-Stil von OpenFreeMap (kostenlos, ohne API-Key).
  /// Daten: OpenStreetMap-Mitwirkende, Schema: OpenMapTiles.
  /// Attribution wird von MapLibre automatisch eingeblendet.
  static const String styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  /// Ungefähre geographische Mitte des Landkreises Ostprignitz-Ruppin.
  static const LatLng oprCenter = LatLng(52.98, 12.70);

  /// Start-Zoomstufe, bei der der Landkreis auf einem Smartphone
  /// vollständig sichtbar ist.
  static const double initialZoom = 8.3;

  /// Grobe Bounding Box des Landkreises OPR (Südwest / Nordost).
  /// Dient zum Zurücksetzen der Kartenansicht.
  static final LatLngBounds oprBounds = LatLngBounds(
    southwest: const LatLng(52.68, 12.20),
    northeast: const LatLng(53.30, 13.15),
  );
}
