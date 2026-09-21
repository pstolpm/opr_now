/// Ein Point of Interest (POI): Sehenswürdigkeit, Naturziel, Badestelle,
/// Gastronomie o.ä. mit Position, Kategorie und Datenquelle.
///
/// Phase 4: Testdaten aus einer lokalen GeoJSON-Datei
/// (assets/data/test_pois.geojson). Spätere Phasen ergänzen echte externe
/// Quellen (OSM/Overpass, Overture, amtliche Badestellen Brandenburg),
/// siehe PROJECT_BRAIN Abschnitt 11 und 21.
class Poi {
  const Poi({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.source,
    this.description,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Grobe Kategorie für Symbolisierung und Filterung, z. B.
  /// 'sehenswuerdigkeit', 'natur', 'badestelle', 'gastronomie'.
  final String category;

  /// Herkunft der Daten (PROJECT_BRAIN Regel 10 – Quellen kenntlich machen),
  /// z. B. 'test', später u. a. 'osm', 'overture', 'brandenburg', 'user'.
  final String source;

  final String? description;

  /// Erstellt einen [Poi] aus einem GeoJSON-Feature mit Point-Geometrie.
  ///
  /// Erwartet Koordinaten in der GeoJSON-Reihenfolge [longitude, latitude]
  /// (PROJECT_BRAIN Abschnitt 34).
  factory Poi.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};

    return Poi(
      id: (feature['id'] ?? properties['id']).toString(),
      name: properties['name'] as String? ?? 'Unbenannt',
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
      category: properties['category'] as String? ?? 'sonstiges',
      source: properties['source'] as String? ?? 'unbekannt',
      description: properties['description'] as String?,
    );
  }
}
