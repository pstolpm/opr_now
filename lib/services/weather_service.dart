import 'package:dio/dio.dart';

import '../models/weather_context.dart';

/// Fehlerarten bei der Wetterabfrage, damit die UI verständliche Meldungen
/// zeigen kann (PROJECT_BRAIN Regel 8 – API-Fehler berücksichtigen).
enum WeatherFailure { timeout, network, invalidResponse, unknown }

class WeatherException implements Exception {
  const WeatherException(this.failure);
  final WeatherFailure failure;
}

/// Ruft aktuelle Wetterdaten über die Open-Meteo-API ab.
///
/// Kein API-Key nötig (PROJECT_BRAIN Abschnitt 11.3). Dokumentation:
/// https://open-meteo.com/en/docs
class WeatherService {
  WeatherService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Variablen für die aktuelle Stunde – bewusst auf das für die
  /// Context Engine relevante Minimum begrenzt (PROJECT_BRAIN Abschnitt 21:
  /// temperature, precipitation, windSpeed, cloudCover).
  static const _currentParams =
      'temperature_2m,precipitation,weather_code,wind_speed_10m,cloud_cover';

  Future<WeatherContext> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _baseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': _currentParams,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const WeatherException(WeatherFailure.invalidResponse);
      }
      return WeatherContext.fromOpenMeteoJson(data);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw const WeatherException(WeatherFailure.timeout);
        case DioExceptionType.connectionError:
          throw const WeatherException(WeatherFailure.network);
        default:
          throw const WeatherException(WeatherFailure.unknown);
      }
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw const WeatherException(WeatherFailure.invalidResponse);
    }
  }
}
