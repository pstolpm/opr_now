/// Aktueller Wetterkontext für eine Position (Open-Meteo, PROJECT_BRAIN
/// Abschnitt 11.3 und 21).
///
/// Wird später von der Context Engine genutzt, um POIs je nach Wetter
/// unterschiedlich zu bewerten (z. B. Outdoor-Ziele bei Regen abwerten).
class WeatherContext {
  const WeatherContext({
    required this.temperature,
    required this.precipitation,
    required this.windSpeed,
    required this.cloudCover,
    required this.weatherCode,
    required this.timestamp,
  });

  /// Lufttemperatur in 2 m Höhe, °C.
  final double temperature;

  /// Niederschlag der aktuellen Stunde, mm.
  final double precipitation;

  /// Windgeschwindigkeit in 10 m Höhe, km/h.
  final double windSpeed;

  /// Bewölkungsgrad, %.
  final double cloudCover;

  /// WMO-Wettercode (0 = klar, steigend = mehr Bewölkung/Niederschlag).
  /// Referenz: https://open-meteo.com/en/docs (Abschnitt "WMO Weather
  /// interpretation codes").
  final int weatherCode;

  final DateTime timestamp;

  factory WeatherContext.fromOpenMeteoJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return WeatherContext(
      temperature: (current['temperature_2m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      cloudCover: (current['cloud_cover'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      timestamp: DateTime.now(),
    );
  }
}
