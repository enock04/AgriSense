// ============================================================
// AgriSense Data Models
// ============================================================

enum WeatherStatus { good, caution, severe }
enum FarmerType { farmer, landowner, trader }
enum LessonFormat { audio, video, text }
enum LessonLevel { beginner, intermediate, advanced, all }

class Crop {
  final String id;
  final String name;
  final String kinyarwanda;
  final String emoji;

  const Crop({
    required this.id,
    required this.name,
    required this.kinyarwanda,
    required this.emoji,
  });
}

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

class Lesson {
  final String id;
  final String title;
  final String titleKin;
  final String cropTag;
  final String topicTag;
  final LessonLevel level;
  final List<LessonFormat> formats;
  final int durationMinutes;
  final double progress;
  final bool isNew;
  final bool isDownloaded;
  final String emoji;
  final String description;
  final String descriptionKin;
  final bool isWomensPathway;

  const Lesson({
    required this.id,
    required this.title,
    required this.titleKin,
    required this.cropTag,
    required this.topicTag,
    required this.level,
    required this.formats,
    required this.durationMinutes,
    required this.progress,
    required this.emoji,
    required this.description,
    required this.descriptionKin,
    this.isNew = false,
    this.isDownloaded = false,
    this.isWomensPathway = false,
  });

  bool get isCompleted => progress >= 1.0;
  bool get isStarted => progress > 0 && progress < 1.0;
}

class CommunityPost {
  final String id;
  final String userName;
  final String userInitials;
  final String district;
  final String question;
  final String questionKin;
  final int upvotes;
  final int replyCount;
  final String timeAgo;
  final String timeAgoKin;
  final bool isUpvoted;

  const CommunityPost({
    required this.id,
    required this.userName,
    required this.userInitials,
    required this.district,
    required this.question,
    required this.questionKin,
    required this.upvotes,
    required this.replyCount,
    required this.timeAgo,
    required this.timeAgoKin,
    this.isUpvoted = false,
  });
}

class UserProfile {
  final String name;
  final String phone;
  final FarmerType farmerType;
  final List<Crop> selectedCrops;
  final String district;
  final String language;

  const UserProfile({
    required this.name,
    required this.phone,
    required this.farmerType,
    required this.selectedCrops,
    required this.district,
    required this.language,
  });
}
