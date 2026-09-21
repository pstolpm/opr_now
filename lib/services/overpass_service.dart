import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:maplibre_gl/maplibre_gl.dart' show LatLngBounds;

import '../models/poi.dart';

/// Fehlerarten bei der Overpass-Abfrage (PROJECT_BRAIN Regel 8).
enum OverpassFailure { timeout, network, invalidResponse, unknown }

class OverpassException implements Exception {
  const OverpassException(this.failure);
  final OverpassFailure failure;
}

/// Lädt POIs aus OpenStreetMap über die Overpass API, begrenzt auf eine
/// feste Bounding Box statt auf jede Kartenbewegung zu reagieren
/// (PROJECT_BRAIN Abschnitt 11.1 / Regel für Overpass: keine großflächigen
/// oder wiederholten Abfragen).
///
/// Dokumentation: https://wiki.openstreetmap.org/wiki/Overpass_API
class OverpassService {
  OverpassService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // Etwas grosszuegiger als der serverseitige Query-Timeout
              // ([out:json][timeout:25] unten), sonst bricht der Client
              // ab, bevor der Overpass-Server ueberhaupt fertig ist.
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 35),
              headers: {
                // Overpass-Fair-Use-Regeln: Anfragen sollen die App
                // eindeutig identifizieren (siehe Overpass-API-Wiki).
                'User-Agent':
                    'OPR-NOW-Studienprojekt (BHT Berlin, Geoinformation)',
              },
            ));

  final Dio _dio;

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Lädt Node-POIs mit einer festen Tag-Auswahl innerhalb von [bounds].
  ///
  /// Nur Nodes (keine Ways/Relations) und nur Elemente mit einem
  /// 'name'-Tag werden berücksichtigt - hält die Abfrage und das Parsen
  /// einfach (MVP, PROJECT_BRAIN Regel 4).
  Future<List<Poi>> loadPois(LatLngBounds bounds) async {
    final bbox = '${bounds.southwest.latitude},${bounds.southwest.longitude},'
        '${bounds.northeast.latitude},${bounds.northeast.longitude}';

    final query = '[out:json][timeout:25];'
        '('
        'node["tourism"~"attraction|museum|artwork|gallery|viewpoint"]($bbox);'
        'node["historic"]($bbox);'
        'node["amenity"~"cafe|restaurant|fast_food|biergarten|pub"]($bbox);'
        'node["natural"="beach"]($bbox);'
        'node["leisure"~"bathing_place|swimming_area|nature_reserve"]($bbox);'
        ');'
        'out body;';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: 'data=${Uri.encodeQueryComponent(query)}',
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data;
      if (data == null) {
        throw const OverpassException(OverpassFailure.invalidResponse);
      }

      final elements = (data['elements'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();

      return elements
          .where((element) {
            final tags = element['tags'] as Map<String, dynamic>?;
            return tags != null &&
                tags['name'] != null &&
                element['lat'] != null &&
                element['lon'] != null;
          })
          .map(Poi.fromOverpassElement)
          .toList();
    } on DioException catch (e) {
      // Sichtbar im `flutter run`-Log, um Fehlschläge einordnen zu können
      // (z. B. Timeout vs. HTTP-Fehler vs. keine Verbindung).
      debugPrint(
        'Overpass-Request fehlgeschlagen: ${e.type}, '
        'Status ${e.response?.statusCode}, ${e.message}',
      );
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw const OverpassException(OverpassFailure.timeout);
        case DioExceptionType.connectionError:
          throw const OverpassException(OverpassFailure.network);
        default:
          throw const OverpassException(OverpassFailure.unknown);
      }
    } on OverpassException {
      rethrow;
    } catch (_) {
      throw const OverpassException(OverpassFailure.invalidResponse);
    }
  }
}
