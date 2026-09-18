/// Herkunft einer Nutzerposition.
enum PositionSource {
  /// Echte Position vom Gerät (GNSS / Fused Location Provider).
  gps,

  /// Simulierte Position aus dem Demo-Modus.
  demo,
}

/// Aktuelle Position des Nutzers - unabhängig davon, ob sie vom GPS oder
/// aus dem Demo-Modus stammt.
///
/// Bewusst ein eigenes, reines Dart-Modell ohne Abhängigkeit zu
/// `geolocator` oder `maplibre_gl`, damit die Fachlogik (Context Engine,
/// Geofence) gegen dieses Modell arbeiten und einfach getestet werden kann.
class UserPosition {
  const UserPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.source,
    this.accuracyMeters,
  });

  /// Geographische Breite in Grad (WGS84).
  final double latitude;

  /// Geographische Länge in Grad (WGS84).
  final double longitude;

  /// Horizontale Genauigkeit in Metern, falls bekannt.
  final double? accuracyMeters;

  final DateTime timestamp;

  final PositionSource source;

  bool get isDemo => source == PositionSource.demo;

  /// Position als GeoJSON-Feature.
  ///
  /// Achtung Koordinatenreihenfolge: GeoJSON verwendet [Länge, Breite]
  /// (PROJECT_BRAIN Abschnitt 34).
  Map<String, dynamic> toGeoJsonFeature() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {
        'source': source.name,
        'accuracy': accuracyMeters,
        'timestamp': timestamp.toIso8601String(),
      },
    };
  }

  @override
  String toString() =>
      'UserPosition(${latitude.toStringAsFixed(5)}, '
      '${longitude.toStringAsFixed(5)}, ${source.name})';
}
