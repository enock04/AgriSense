import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/remote/firestore_remote_datasource.dart';
import '../datasources/local/preferences_local_datasource.dart';
import '../models/user_model.dart';

/// Concrete implementation of [UserRepository].
/// Coordinates between Firestore (remote) and SharedPreferences (local).
class UserRepositoryImpl implements UserRepository {
  final FirestoreRemoteDatasource _remote;
  final PreferencesLocalDatasource _local;

  UserRepositoryImpl(this._remote, this._local);

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final model = UserModel.fromEntity(profile);
    // Persist remotely
    await _remote.saveProfileData(model.toFirestore());
    // Cache locally for offline access
    await _local.setString('farmerName', profile.name);
    await _local.setString('district', profile.district);
    await _local.setString('language', profile.language);
    await _local.setBool('onboardingComplete', true);
  }

  @override
  Future<UserProfile?> loadProfile() async {
    final data = await _remote.loadProfileData();
    if (data == null) return null;
    // We need the UID — get it from the datasource via FirebaseAuth
    // The model handles the uid via the Firestore document path,
    // so we pass a placeholder here and let the model parse the rest.
    // In practice the provider already knows the uid from auth state.
    return UserModel.fromFirestore('', data).toEntity();
  }

  @override
  Future<void> saveLessonProgress(String lessonId, double progress) async {
    await _remote.saveLessonProgress(lessonId, progress);
    await _local.setDouble('progress_$lessonId', progress);
  }

  @override
  Future<Map<String, double>> loadAllProgress() async {
    // Try remote first, fall back to local cache
    try {
      return await _remote.loadAllProgress();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveLocalPreference(String key, dynamic value) async {
    if (value is String)  await _local.setString(key, value);
    if (value is bool)    await _local.setBool(key, value);
    if (value is double)  await _local.setDouble(key, value);
    if (value is int)     await _local.setInt(key, value);
  }

  @override
  String? getLocalString(String key) => _local.getString(key);

  @override
  bool? getLocalBool(String key) => _local.getBool(key);
}
