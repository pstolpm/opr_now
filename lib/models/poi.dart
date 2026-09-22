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
    this.details,
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

  /// Zusätzliche, quellenspezifische Detailfelder (z. B. Ausstattung einer
  /// Badestelle: Parkplatz, WC, Strandbeschaffenheit, Bewertung, ...).
  /// Optional, da nicht jede Quelle solche Details liefert.
  final Map<String, String>? details;

  /// Erstellt einen [Poi] aus einem GeoJSON-Feature mit Point-Geometrie.
  ///
  /// Erwartet Koordinaten in der GeoJSON-Reihenfolge [longitude, latitude]
  /// (PROJECT_BRAIN Abschnitt 34).
  factory Poi.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};

    final rawDetails = properties['details'];

    return Poi(
      id: (feature['id'] ?? properties['id']).toString(),
      name: properties['name'] as String? ?? 'Unbenannt',
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
      category: properties['category'] as String? ?? 'sonstiges',
      source: properties['source'] as String? ?? 'unbekannt',
      description: properties['description'] as String?,
      details: rawDetails is Map
          ? rawDetails.map((key, value) => MapEntry(key.toString(), value.toString()))
          : null,
    );
  }

  /// Erstellt einen [Poi] aus einem Overpass-API-Element (Node mit Tags).
  ///
  /// Erwartet, dass `tags['name']`, `lat` und `lon` vorhanden sind - das
  /// wird bereits beim Laden in [OverpassService] gefiltert.
  factory Poi.fromOverpassElement(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>;
    return Poi(
      id: 'osm:${element['id']}',
      name: tags['name'] as String,
      latitude: (element['lat'] as num).toDouble(),
      longitude: (element['lon'] as num).toDouble(),
      category: _categoryFromOsmTags(tags),
      source: 'osm',
      description: tags['tourism'] as String? ??
          tags['historic'] as String? ??
          tags['amenity'] as String? ??
          tags['leisure'] as String? ??
          tags['natural'] as String?,
    );
  }

  /// Ordnet OSM-Tags einer der vier App-Kategorien zu (siehe
  /// [OverpassService] und die Farbgebung in map_screen.dart). Eine
  /// vollständige/endgültige Kategorisierung ist eine offene Entscheidung
  /// (PROJECT_BRAIN Abschnitt 48).
  static String _categoryFromOsmTags(Map<String, dynamic> tags) {
    final tourism = tags['tourism'] as String?;
    final leisure = tags['leisure'] as String?;

    if (tourism == 'viewpoint' || leisure == 'nature_reserve') {
      return 'natur';
    }
    if (tags.containsKey('historic') ||
        (tourism != null &&
            ['attraction', 'museum', 'artwork', 'gallery'].contains(tourism))) {
      return 'sehenswuerdigkeit';
    }
    if (tags['natural'] == 'beach' ||
        leisure == 'bathing_place' ||
        leisure == 'swimming_area') {
      return 'badestelle';
    }
    final amenity = tags['amenity'] as String?;
    if (amenity != null &&
        ['cafe', 'restaurant', 'fast_food', 'biergarten', 'pub']
            .contains(amenity)) {
      return 'gastronomie';
    }
    return 'sonstiges';
  }
}
