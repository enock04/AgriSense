import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/weather.dart';
import '../../mock_data.dart';

/// Raw OpenWeatherMap API access + fallback to mock data.
/// No business logic beyond response parsing — only data access.
class WeatherRemoteDatasource {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  String get _apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  // ── District name → coordinates lookup (Rwanda districts) ──────────────
  // OpenWeatherMap works best with lat/lon for small districts.
  static const Map<String, List<double>> _districtCoords = {
    'Musanze':    [-1.4997, 29.6347],
    'Nyagatare':  [-1.2984, 30.3278],
    'Huye':       [-2.5967, 29.7397],
    'Rubavu':     [-1.6875, 29.3603],
    'Kamonyi':    [-2.0056, 29.8762],
    'Gasabo':     [-1.9441, 30.0619],
    'Kicukiro':   [-1.9997, 30.0900],
    'Nyarugenge': [-1.9536, 30.0606],
    'Ruhango':    [-2.2214, 29.7733],
    'Muhanga':    [-2.0830, 29.7553],
    'Rulindo':    [-1.7264, 30.0512],
    'Nyabihu':    [-1.6542, 29.4997],
  };

  // ── Fetch current weather + 7-day forecast ──────────────────────────────
  Future<WeatherData> fetchWeather(String district) async {
    try {
      final coords = _districtCoords[district] ?? _districtCoords['Musanze']!;
      final lat = coords[0];
      final lon = coords[1];

      // Parallel requests: current weather + 5-day/3-hour forecast
      final responses = await Future.wait([
        http.get(Uri.parse(
            '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric')),
        http.get(Uri.parse(
            '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&cnt=40')),
      ]);

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        throw Exception('API error: ${responses[0].statusCode}');
      }

      final current = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final forecast = jsonDecode(responses[1].body) as Map<String, dynamic>;

      return _parse(district, current, forecast);
    } catch (e) {
      // Graceful fallback to mock data when offline or API fails
      return district.contains('Nyagatare')
          ? MockData.severeWeather
          : MockData.goodWeather;
    }
  }

  // ── Parse OpenWeatherMap JSON → WeatherData ─────────────────────────────
  WeatherData _parse(
    String district,
    Map<String, dynamic> current,
    Map<String, dynamic> forecastData,
  ) {
    final mainData = current['main'] as Map<String, dynamic>? ?? {};
    final temp = ((mainData['temp'] as num?) ?? 20).round();
    final feelsLike = ((mainData['feels_like'] as num?) ?? 18).round();
    final humidity = ((mainData['humidity'] as num?) ?? 65).round();
    final windSpeed = ((current['wind']?['speed'] as num?) ?? 0).toDouble() * 3.6;
    final weatherList = current['weather'] as List?;
    final weatherId = weatherList != null && weatherList.isNotEmpty
        ? (weatherList[0]['id'] as int? ?? 800)
        : 800;
    final description = weatherList != null && weatherList.isNotEmpty
        ? (weatherList[0]['description'] as String? ?? 'clear sky')
        : 'clear sky';
    final rainChance = current['rain'] != null ? 1.0 : 0.1;
    final uvIndex = 3; // Current API requires separate UV call; default for now

    final status = _toStatus(weatherId, rainChance);
    final emoji = _toEmoji(weatherId);
    final advisory = _toAdvisory(status, description);

    // Build 7-day forecast from 3-hour intervals (pick midday entry per day)
    final forecastList = forecastData['list'] as List;
    final Map<String, dynamic> dayMap = {};
    for (final item in forecastList) {
      final dtVal = (item['dt'] as int?) ?? 0;
      final dt = DateTime.fromMillisecondsSinceEpoch(dtVal * 1000, isUtc: true);
      final dayKey = '${dt.year}-${dt.month}-${dt.day}';
      // Pick the 12:00 entry (or first available) for each day
      if (!dayMap.containsKey(dayKey) || dt.hour == 12) {
        dayMap[dayKey] = item;
      }
    }

    final days = dayMap.values.take(7).toList();
    final forecastDays = <ForecastDay>[];
    final dayLabels = ['Today', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < days.length; i++) {
      final item = days[i] as Map<String, dynamic>;
      final itemTemp = ((item['main']?['temp'] as num?) ?? 20).round();
      final weatherList = item['weather'] as List?;
      final itemId = weatherList != null && weatherList.isNotEmpty
          ? (weatherList[0]['id'] as int? ?? 800)
          : 800;
      final pop = (item['pop'] as num?)?.toDouble() ?? 0.0; // probability of precipitation
      final itemStatus = _toStatus(itemId, pop);

      forecastDays.add(ForecastDay(
        dayLabel: i == 0 ? 'Today' : _dayLabel(days[i], dayLabels),
        weatherEmoji: _toEmoji(itemId),
        tempCelsius: itemTemp,
        actionWord: _toActionWord(itemStatus, pop),
        status: itemStatus,
        rainChance: pop,
      ));
    }

    // Check for severe alert (wind > 50 km/h or heavy rain)
    final hasSevere = windSpeed > 50 || (status == WeatherStatus.severe);
    final province = _districtToProvince(district);

    return WeatherData(
      district: district,
      province: province,
      temperature: temp,
      feelsLike: feelsLike,
      humidity: humidity,
      rainChance: rainChance,
      windSpeed: windSpeed,
      uvIndex: uvIndex,
      conditionEmoji: emoji,
      status: status,
      advisoryText: advisory.$1,
      advisoryKin: advisory.$2,
      forecast: forecastDays,
      hasSevereAlert: hasSevere,
      alertTitle: hasSevere ? '⚠️ Severe Weather Alert · $district' : null,
      alertBody: hasSevere
          ? 'Strong winds or heavy rain expected. Avoid field work today.'
          : null,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  WeatherStatus _toStatus(int weatherId, double rainChance) {
    // OWM weather codes: 2xx = thunderstorm, 5xx = rain, 6xx = snow
    if (weatherId >= 200 && weatherId < 300) return WeatherStatus.severe;
    if (rainChance >= 0.7) return WeatherStatus.severe;
    if (rainChance >= 0.4 || (weatherId >= 500 && weatherId < 600)) {
      return WeatherStatus.caution;
    }
    return WeatherStatus.good;
  }

  String _toEmoji(int id) {
    if (id >= 200 && id < 300) return '⛈';
    if (id >= 300 && id < 400) return '🌦';
    if (id >= 500 && id < 510) return '🌧';
    if (id == 511) return '🌨';
    if (id >= 520 && id < 600) return '🌦';
    if (id >= 600 && id < 700) return '❄️';
    if (id >= 700 && id < 800) return '🌫';
    if (id == 800) return '☀';
    if (id == 801 || id == 802) return '⛅';
    return '☁';
  }

  String _toActionWord(WeatherStatus status, double rainChance) {
    switch (status) {
      case WeatherStatus.severe:
        return 'PROTECT';
      case WeatherStatus.caution:
        return rainChance > 0.6 ? 'WAIT' : 'IRRIGATE';
      case WeatherStatus.good:
        return rainChance < 0.1 ? 'HARVEST' : 'PLANT';
    }
  }

  (String, String) _toAdvisory(WeatherStatus status, String description) {
    switch (status) {
      case WeatherStatus.severe:
        return (
          'SEVERE: Do NOT enter fields today. Risk of flooding or strong winds.',
          'AKAZI: Ntugire akazi ko mu mirima uyu munsi. Ingaruka z\'ibyondo.',
        );
      case WeatherStatus.caution:
        return (
          'Caution: $description expected. Delay planting or harvesting if possible.',
          'Witondere: Imvura irashobora kuza. Tegereza igihe cyiza.',
        );
      case WeatherStatus.good:
        return (
          'Good conditions for field work today. Low rainfall risk.',
          'Ibihe ni byiza byo gukorera mu mirima uyu munsi.',
        );
    }
  }

  String _dayLabel(dynamic item, List<String> labels) {
    final dtVal = (item['dt'] as int?) ?? 0;
    final dt = DateTime.fromMillisecondsSinceEpoch(dtVal * 1000, isUtc: true);
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dt.weekday % 7];
  }

  String _districtToProvince(String district) {
    const map = {
      'Musanze': 'Northern Province', 'Rulindo': 'Northern Province',
      'Nyagatare': 'Eastern Province',
      'Huye': 'Southern Province', 'Kamonyi': 'Southern Province',
      'Ruhango': 'Southern Province', 'Muhanga': 'Southern Province',
      'Rubavu': 'Western Province', 'Nyabihu': 'Western Province',
      'Gasabo': 'Kigali City', 'Kicukiro': 'Kigali City', 'Nyarugenge': 'Kigali City',
    };
    return map[district] ?? 'Rwanda';
  }
}
