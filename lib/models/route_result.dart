import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

/// Ergebnis einer Routenberechnung (PROJECT_BRAIN Abschnitt 7, 21).
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.profile,
  });

  /// Streckenverlauf, dekodiert aus der von Valhalla gelieferten Polyline.
  final List<LatLng> points;

  final double distanceMeters;
  final double durationSeconds;

  /// Valhalla-"costing"-Profil, z. B. 'pedestrian' oder 'bicycle'.
  final String profile;
}
