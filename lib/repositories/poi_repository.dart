import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/poi.dart';

/// Lädt POIs aus einer lokalen GeoJSON-Datei im Asset-Bundle.
///
/// Generisch für jede Quelle, die als lokale GeoJSON-Datei vorliegt: die
/// Phase-4-Testdaten, aber auch per ETL-Skript (tools/) erzeugte Dateien wie
/// die amtlichen Badestellen Brandenburg oder eine Overture-Teilmenge
/// (siehe PROJECT_BRAIN Abschnitt 11, 44). Live-Quellen wie Overpass haben
/// einen eigenen Service (siehe OverpassService), da sie über HTTP statt
/// aus dem Asset-Bundle geladen werden.
class PoiRepository {
  const PoiRepository({this.assetPath = 'assets/data/test_pois.geojson'});

  final String assetPath;

  Future<List<Poi>> loadPois() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final features = (json['features'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return features.map(Poi.fromGeoJsonFeature).toList();
  }
}
