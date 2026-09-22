import 'package:dio/dio.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../models/route_result.dart';

/// Fehlerarten bei der Routenberechnung (PROJECT_BRAIN Regel 8).
enum RoutingFailure { timeout, network, noRoute, invalidResponse, unknown }

class RoutingException implements Exception {
  const RoutingException(this.failure);
  final RoutingFailure failure;
}

/// Berechnet Routen über den kostenlosen, von FOSSGIS (deutsche
/// OpenStreetMap-Community) betriebenen Valhalla-Server. Kein API-Key
/// nötig; der Dienst ist laut FOSSGIS ausdrücklich auch für die Einbindung
/// in eigene Apps freigegeben (PROJECT_BRAIN Abschnitt 7, 48).
///
/// Dokumentation: https://valhalla.github.io/valhalla/api/route/api-reference/
/// Server: https://valhalla.openstreetmap.de/
class RoutingService {
  RoutingService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                'User-Agent':
                    'OPR-NOW-Studienprojekt (BHT Berlin, Geoinformation)',
              },
            ));

  final Dio _dio;

  static const _endpoint = 'https://valhalla1.openstreetmap.de/route';

  /// [profile] ist ein Valhalla-"costing"-Wert, für den MVP 'pedestrian'
  /// oder 'bicycle'.
  Future<RouteResult> getRoute({
    required LatLng start,
    required LatLng destination,
    required String profile,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: {
          'locations': [
            {'lat': start.latitude, 'lon': start.longitude},
            {'lat': destination.latitude, 'lon': destination.longitude},
          ],
          'costing': profile,
          'units': 'kilometers',
        },
      );

      final trip = response.data?['trip'] as Map<String, dynamic>?;
      final legs = trip?['legs'] as List<dynamic>?;
      final summary = trip?['summary'] as Map<String, dynamic>?;
      if (trip == null || legs == null || legs.isEmpty || summary == null) {
        throw const RoutingException(RoutingFailure.invalidResponse);
      }

      final shape = (legs.first as Map<String, dynamic>)['shape'] as String?;
      if (shape == null) {
        throw const RoutingException(RoutingFailure.invalidResponse);
      }

      return RouteResult(
        points: _decodePolyline(shape),
        // 'units: kilometers' -> summary.length ist in km.
        distanceMeters: (summary['length'] as num).toDouble() * 1000,
        durationSeconds: (summary['time'] as num).toDouble(),
        profile: profile,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Valhalla antwortet bei nicht auffindbarer Route mit HTTP 400.
        throw const RoutingException(RoutingFailure.noRoute);
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw const RoutingException(RoutingFailure.timeout);
        case DioExceptionType.connectionError:
          throw const RoutingException(RoutingFailure.network);
        default:
          throw const RoutingException(RoutingFailure.unknown);
      }
    } on RoutingException {
      rethrow;
    } catch (_) {
      throw const RoutingException(RoutingFailure.invalidResponse);
    }
  }

  /// Dekodiert eine Google-/Valhalla-Polyline mit Präzision 6 (statt der
  /// sonst üblichen 5) - Standardalgorithmus, siehe Valhalla-Doku
  /// (https://valhalla.github.io/valhalla/decoding/).
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lon = 0;

    int readDelta() {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index) - 63;
        index++;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    }

    while (index < encoded.length) {
      lat += readDelta();
      lon += readDelta();
      points.add(LatLng(lat / 1e6, lon / 1e6));
    }
    return points;
  }
}
