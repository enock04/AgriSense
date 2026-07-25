import 'package:flutter/material.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../data/mock_data.dart';

enum WeatherLoadState { idle, loading, loaded, error }

/// Manages current weather data for the selected district.
class WeatherProvider extends ChangeNotifier {
  final WeatherRepository _weatherRepository;

  WeatherProvider(this._weatherRepository);

  WeatherData _currentWeather = MockData.goodWeather;
  WeatherData get currentWeather => _currentWeather;

  WeatherLoadState _state = WeatherLoadState.idle;
  WeatherLoadState get state => _state;

  String _error = '';
  String get error => _error;

  bool get isLoading       => _state == WeatherLoadState.loading;
  bool get showSevereAlert => _currentWeather.status == WeatherStatus.severe;

  Future<void> fetchWeather(String district) async {
    if (district.isEmpty) return;
    _state = WeatherLoadState.loading;
    _error = '';
    notifyListeners();

    try {
      _currentWeather = await _weatherRepository.fetchWeather(district);
      _state = WeatherLoadState.loaded;
    } catch (_) {
      _error = 'Could not load weather. Showing last known data.';
      _state = WeatherLoadState.error;
    }
    notifyListeners();
  }

  /// Toggle between good/severe weather for demo purposes (debug only).
  void toggleScenario() {
    _currentWeather = _currentWeather.status == WeatherStatus.good
        ? MockData.severeWeather
        : MockData.goodWeather;
    notifyListeners();
  }
}
