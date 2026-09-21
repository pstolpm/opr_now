import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/poi.dart';

/// Lädt POIs aus einer lokalen GeoJSON-Datei im Asset-Bundle.
///
/// Phase 4: nur die lokale Testdatei (assets/data/test_pois.geojson).
/// Ab Phase 5 treten weitere Repositories für externe Quellen hinzu
/// (OSM/Overpass, Overture, amtliche Badestellen) – siehe PROJECT_BRAIN
/// Abschnitt 11.
class PoiRepository {
  const PoiRepository({this.assetPath = 'assets/data/test_pois.geojson'});

  final String assetPath;

  Future<List<Poi>> loadTestPois() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = (json['features'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return features.map(Poi.fromGeoJsonFeature).toList();
  }
}
