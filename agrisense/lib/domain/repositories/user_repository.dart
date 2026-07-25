import '../entities/user_profile.dart';

/// Contract for user profile and lesson-progress persistence.
abstract class UserRepository {
  /// Save or update the farmer's profile.
  Future<void> saveProfile(UserProfile profile);

  /// Load profile for the currently signed-in user. Returns null if not found.
  Future<UserProfile?> loadProfile();

  /// Save lesson progress (0.0 – 1.0) both locally and remotely.
  Future<void> saveLessonProgress(String lessonId, double progress);

  /// Load all lesson progress values for the current user.
  Future<Map<String, double>> loadAllProgress();

  /// Persist a single preference value locally.
  Future<void> saveLocalPreference(String key, dynamic value);

  /// Read a previously saved string preference.
  String? getLocalString(String key);

  /// Read a previously saved bool preference.
  bool? getLocalBool(String key);
}
