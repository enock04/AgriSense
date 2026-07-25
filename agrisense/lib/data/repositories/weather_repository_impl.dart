import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/remote/weather_remote_datasource.dart';

/// Concrete implementation of [WeatherRepository].
/// Delegates to [WeatherRemoteDatasource] which handles
/// OpenWeatherMap API calls and fallback to mock data.
class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDatasource _service;

  WeatherRepositoryImpl(this._service);

  @override
  Future<WeatherData> fetchWeather(String district) =>
      _service.fetchWeather(district);
}
