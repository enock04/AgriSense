import '../entities/weather.dart';

/// Contract for fetching weather data.
abstract class WeatherRepository {
  /// Fetch current weather and 5-day forecast for [district].
  Future<WeatherData> fetchWeather(String district);
}
