/// Weather condition severity levels.
enum WeatherStatus { good, caution, severe }

/// A single day in the forecast strip.
class ForecastDay {
  final String dayLabel;
  final String weatherEmoji;
  final int tempCelsius;
  final String actionWord;
  final WeatherStatus status;
  final double rainChance;

  const ForecastDay({
    required this.dayLabel,
    required this.weatherEmoji,
    required this.tempCelsius,
    required this.actionWord,
    required this.status,
    required this.rainChance,
  });
}

/// Full weather data for a district.
class WeatherData {
  final String district;
  final String province;
  final int temperature;
  final int feelsLike;
  final int humidity;
  final double rainChance;
  final double windSpeed;
  final int uvIndex;
  final String conditionEmoji;
  final WeatherStatus status;
  final String advisoryText;
  final String advisoryKin;
  final List<ForecastDay> forecast;
  final bool hasSevereAlert;
  final String? alertTitle;
  final String? alertBody;

  const WeatherData({
    required this.district,
    required this.province,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.rainChance,
    required this.windSpeed,
    required this.uvIndex,
    required this.conditionEmoji,
    required this.status,
    required this.advisoryText,
    required this.advisoryKin,
    required this.forecast,
    this.hasSevereAlert = false,
    this.alertTitle,
    this.alertBody,
  });
}
