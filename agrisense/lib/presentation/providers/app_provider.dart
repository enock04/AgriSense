import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/farmer_type.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weather.dart';
import '../../domain/entities/community_post.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/phone_credential.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../domain/repositories/community_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/mock_data.dart';

// Re-export auth state enum so screens importing this file still compile.
import 'auth_provider.dart' show AppAuthState;
export 'auth_provider.dart' show AppAuthState;

enum WeatherLoadState { idle, loading, loaded, error }

/// Presentation-layer coordinator.
/// Delegates all data operations to domain repositories (Clean Architecture).
/// UI screens only interact with this provider — they have no direct
/// dependency on Firebase, Firestore, or any data-layer class.
class AppProvider extends ChangeNotifier {
  // ── Injected repositories (Clean Architecture: data layer) ───────────────
  final AuthRepository     _authRepo;
  final UserRepository     _userRepo;
  final WeatherRepository  _weatherRepo;
  final LessonRepository   _lessonRepo;
  final CommunityRepository _communityRepo;
  final NotificationRepository _notificationRepo;

  AppProvider({
    required AuthRepository     authRepository,
    required UserRepository     userRepository,
    required WeatherRepository  weatherRepository,
    required LessonRepository   lessonRepository,
    required CommunityRepository communityRepository,
    required NotificationRepository notificationRepository,
  })  : _authRepo      = authRepository,
        _userRepo      = userRepository,
        _weatherRepo   = weatherRepository,
        _lessonRepo    = lessonRepository,
        _communityRepo = communityRepository,
        _notificationRepo = notificationRepository {
    _init();
  }

  // ── Tab navigation ────────────────────────────────────────────────────────
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;
  void navigateToTab(int i) { _selectedTabIndex = i; notifyListeners(); }

  // ── Auth state ────────────────────────────────────────────────────────────
  AuthUser? _authUser;
  AuthUser? get authUser => _authUser;
  bool get isAuthenticated => _authUser != null;

  AppAuthState _authState = AppAuthState.loading;
  AppAuthState get authState => _authState;
  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  // ── Profile ───────────────────────────────────────────────────────────────
  UserProfile? _profile;
  FarmerType get farmerType   => _profile?.farmerType ?? FarmerType.farmer;
  String get farmerName       => _profile?.name ?? '';
  String get phone            => _profile?.phone ?? '';
  String get district         => _profile?.district ?? '';
  String get language         => _profile?.language ?? 'rw';
  List<Crop> get selectedCrops => _profile?.selectedCrops ?? [];

  // ── Admin ─────────────────────────────────────────────────────────────────
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  // ── Weather ───────────────────────────────────────────────────────────────
  WeatherData _currentWeather = MockData.goodWeather;
  WeatherData get currentWeather => _currentWeather;
  WeatherLoadState _weatherState = WeatherLoadState.idle;
  WeatherLoadState get weatherState => _weatherState;
  String _weatherError = '';
  String get weatherError => _weatherError;
  bool get isWeatherLoading => _weatherState == WeatherLoadState.loading;
  bool get showSevereWeather => _currentWeather.status == WeatherStatus.severe;

  // ── Lessons ───────────────────────────────────────────────────────────────
  List<Lesson> _lessons = [];
  List<Lesson> get lessons => _lessons.isEmpty ? MockData.lessons : _lessons;
  bool _lessonsLoaded = false;
  bool get lessonsLoaded => _lessonsLoaded;
  final Map<String, double> _lessonProgress = {};

  // ── Today's tip ───────────────────────────────────────────────────────────
  Map<String, String>? _todaysTip;
  Map<String, String> get todaysTip => _todaysTip ?? MockData.tipOfDay;

  // ── Community upvote cache ────────────────────────────────────────────────
  final Set<String> _upvotedPosts = {};
  Set<String> get upvotedPosts => Set.unmodifiable(_upvotedPosts);

  // ── Error messaging (Snackbar surface) ───────────────────────────────────
  String _lastError = '';
  String get lastError => _lastError;

  void _setError(String msg) {
    _lastError = msg;
    notifyListeners();
  }

  void clearError() {
    if (_lastError.isEmpty) return;
    _lastError = '';
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  bool _offlineDownloadEnabled = false;
  bool get offlineDownloadEnabled => _offlineDownloadEnabled;

  Future<void> setNotifications(bool v) async {
    _notificationsEnabled = v;
    await _userRepo.saveLocalPreference('notifications', v);
    notifyListeners();

    if (v) {
      final granted = await _notificationRepo.requestPermission();
      if (granted) {
        await _notificationRepo.subscribeToAlerts(district);
        if (_authUser != null) await _notificationRepo.syncTokenForUser(_authUser!.uid);
      }
    } else {
      await _notificationRepo.unsubscribeFromAlerts(district);
    }
  }

  /// Subscribes to district alert topics without ever showing an OS
  /// permission prompt — safe to call on every cold start / profile load.
  Future<void> _setupNotificationsSilently() async {
    if (!_notificationsEnabled) return;
    try {
      await _notificationRepo.subscribeToAlerts(district);
      if (await _notificationRepo.hasPermission() && _authUser != null) {
        await _notificationRepo.syncTokenForUser(_authUser!.uid);
      }
    } catch (_) {}
  }

  Future<void> setOfflineDownload(bool v) async {
    _offlineDownloadEnabled = v;
    await _userRepo.saveLocalPreference('offlineDownload', v);
    notifyListeners();
  }

  // ── Community stream (exposed for CommunityScreen) ────────────────────────
  Stream<List<CommunityPost>> get communityPostsStream => _communityRepo.postsStream();

  // ─────────────────────────────────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    // Set up FCM/local-notification handling. No permission prompt yet.
    try { await _notificationRepo.initialize(); } catch (_) {}

    // Load local preferences
    _notificationsEnabled  = _userRepo.getLocalBool('notifications')  ?? true;
    _offlineDownloadEnabled= _userRepo.getLocalBool('offlineDownload') ?? false;
    _onboardingComplete    = _userRepo.getLocalBool('onboardingComplete') ?? false;

    // Fast sync from local cache
    final cachedUser = _authRepo.currentUser;
    if (cachedUser != null) {
      _authUser = cachedUser;
      _authState = _onboardingComplete
          ? AppAuthState.ready
          : AppAuthState.needsProfile;
    } else {
      _authState = AppAuthState.unauthenticated;
    }
    notifyListeners();

    // Listen to live auth changes
    _authRepo.authStateChanges.listen((user) async {
      _authUser = user;
      if (user != null) {
        await _loadFromRepository();
        _authState = _onboardingComplete
            ? AppAuthState.ready
            : AppAuthState.needsProfile;
      } else {
        _authState = AppAuthState.unauthenticated;
        _onboardingComplete = false;
      }
      notifyListeners();
    });

    if (district.isNotEmpty) await refreshWeather();
  }

  // ── Load profile from repository ─────────────────────────────────────────

  Future<void> _loadFromRepository() async {
    try {
      // Load progress from repository
      final progress = await _userRepo.loadAllProgress();
      _lessonProgress.addAll(progress);

      final profileData = await _userRepo.loadProfile();
      if (profileData != null) {
        // Inject UID from current user
        _profile = UserProfile(
          uid: _authUser?.uid ?? '',
          name: profileData.name,
          phone: profileData.phone,
          farmerType: profileData.farmerType,
          selectedCrops: profileData.selectedCrops,
          district: profileData.district,
          language: profileData.language,
        );
        _onboardingComplete = true;
        await _userRepo.saveLocalPreference('onboardingComplete', true);
        notifyListeners();
        await refreshWeather();
        _loadLessons();
        _loadTip();
        _checkAdmin();
        _setupNotificationsSilently();
      }
    } catch (e) {
      _setError('Could not load your profile. Check your connection.');
    }
  }

  void _loadLessons() {
    _lessonRepo.lessonsStream().listen((incoming) {
      if (incoming.isNotEmpty) {
        _lessons = incoming.map((l) =>
            l.withProgress(_lessonProgress[l.id] ?? l.progress)).toList();
        _lessonsLoaded = true;
        notifyListeners();
      }
    }, onError: (_) {});
  }

  Future<void> _loadTip() async {
    final tip = await _lessonRepo.getTodaysTip();
    if (tip != null) { _todaysTip = tip; notifyListeners(); }
  }

  Future<void> _checkAdmin() async {
    _isAdmin = await _lessonRepo.isAdmin(storedPhone: phone);
    if (_isAdmin) notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Weather
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> refreshWeather() async {
    _weatherState = WeatherLoadState.loading;
    _weatherError = '';
    notifyListeners();
    try {
      final d = district.isNotEmpty ? district : 'Musanze';
      _currentWeather = await _weatherRepo.fetchWeather(d);
      _weatherState = WeatherLoadState.loaded;
    } catch (e) {
      _weatherError = 'Could not load weather. Showing last known data.';
      _weatherState = WeatherLoadState.error;
      _setError('Weather update failed. Check your connection and try again.');
    }
    notifyListeners();
  }

  Future<void> selectDistrict(String d) async {
    if (_profile == null) return;
    final oldDistrict = district;
    _profile = _profile!.copyWith(district: d);
    await _userRepo.saveLocalPreference('district', d);
    notifyListeners();
    await refreshWeather();

    if (_notificationsEnabled && oldDistrict.isNotEmpty && oldDistrict != d) {
      try {
        await _notificationRepo.unsubscribeFromAlerts(oldDistrict);
        await _notificationRepo.subscribeToAlerts(d);
      } catch (_) {}
    }
  }

  void toggleWeatherScenario() {
    _currentWeather = _currentWeather.status == WeatherStatus.good
        ? MockData.severeWeather
        : MockData.goodWeather;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Onboarding / Profile
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> completeOnboarding({
    required String name,
    required String phone,
    required FarmerType farmerType,
    required List<Crop> crops,
    required String district,
    required String language,
  }) async {
    final newProfile = UserProfile(
      uid: _authUser?.uid ?? '',
      name: name, phone: phone, farmerType: farmerType,
      selectedCrops: crops, district: district, language: language,
    );
    _profile = newProfile;
    _onboardingComplete = true;
    _authState = AppAuthState.ready;
    notifyListeners();

    // Persist via repository (remote + local)
    try {
      await _userRepo.saveProfile(newProfile);
    } catch (e) {
      _setError('Profile saved locally but sync failed. Will retry when online.');
    }

    // Seed initial content (best-effort — failures don't block onboarding)
    try { await _communityRepo.seedPostsIfEmpty(); } catch (e) { debugPrint('Seed posts failed: $e'); }
    try { await _lessonRepo.seedLessonsIfEmpty(); } catch (e) { debugPrint('Seed lessons failed: $e'); }
    try { await _lessonRepo.seedTipsIfEmpty(); } catch (e) { debugPrint('Seed tips failed: $e'); }

    await refreshWeather();
    _loadLessons();
    _loadTip();
    _checkAdmin();
    _setupNotificationsSilently();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auth: Google Sign-In
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle({required void Function(String) onError}) async {
    try {
      final ok = await _authRepo.signInWithGoogle(onError: onError);
      // Auth state listener in _init() handles profile load/routing either way.
      return ok;
    } catch (e) {
      onError(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Auth: Phone OTP
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneCredential credential) onAutoVerified,
  }) =>
      _authRepo.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
        onAutoVerified: onAutoVerified,
      );

  Future<bool> verifyOtp({
    required String smsCode,
    required void Function(String) onError,
  }) =>
      _authRepo.verifyOtp(smsCode: smsCode, onError: onError);

  Future<bool> signInWithPhoneCredential(PhoneCredential credential) =>
      _authRepo.signInWithCredential(credential);

  Future<void> setLanguage(String lang) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(language: lang);
    await _userRepo.saveLocalPreference('language', lang);
    if (isAuthenticated) await _userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> setFarmerName(String name) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(name: name);
    if (isAuthenticated) await _userRepo.saveProfile(_profile!);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Lesson Progress
  // ─────────────────────────────────────────────────────────────────────────

  double getLessonProgress(String id) => _lessonProgress[id] ?? 0.0;

  Future<void> updateLessonProgress(String id, double progress) async {
    _lessonProgress[id] = progress.clamp(0.0, 1.0);
    _lessons = _lessons.map((l) =>
        l.id == id ? l.withProgress(_lessonProgress[id]!) : l).toList();
    notifyListeners();
    try {
      await _userRepo.saveLessonProgress(id, _lessonProgress[id]!);
    } catch (e) {
      _setError('Progress saved locally but cloud sync failed.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Community
  // ─────────────────────────────────────────────────────────────────────────

  void toggleUpvote(String postId) {
    if (_upvotedPosts.contains(postId)) {
      _upvotedPosts.remove(postId);
    } else {
      _upvotedPosts.add(postId);
    }
    notifyListeners();
    unawaited(_communityRepo.toggleUpvote(postId));
  }

  bool isUpvoted(String postId) => _upvotedPosts.contains(postId);

  Future<void> addPost({
    required String question,
    required String questionKin,
    required String userName,
    required String district,
  }) =>
      _communityRepo.addPost(
        question: question, questionKin: questionKin,
        userName: userName, district: district,
      );

  Future<void> deletePost(String postId) => _communityRepo.deletePost(postId);

  // ─────────────────────────────────────────────────────────────────────────
  // Admin content management (lessons & tips)
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Lesson>> getAllLessonsAdmin() => _lessonRepo.getAllLessonsAdmin();

  Future<String?> saveLesson(Lesson lesson) => _lessonRepo.saveLesson(lesson);

  Future<void> deleteLesson(String id) => _lessonRepo.deleteLesson(id);

  Future<List<Map<String, dynamic>>> getAllTipsAdmin() => _lessonRepo.getAllTipsAdmin();

  Future<String?> saveTip({
    required String id,
    required String title,
    required String titleKin,
    required String body,
    required String bodyKin,
    required String emoji,
  }) =>
      _lessonRepo.saveTip(
        id: id, title: title, titleKin: titleKin,
        body: body, bodyKin: bodyKin, emoji: emoji,
      );

  Future<void> deleteTip(String id) => _lessonRepo.deleteTip(id);

  // ─────────────────────────────────────────────────────────────────────────
  // Reset
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> resetOnboarding() async {
    await _authRepo.signOut();
    _profile = null;
    _onboardingComplete = false;
    _lessons = [];
    _todaysTip = null;
    _lessonProgress.clear();
    _upvotedPosts.clear();
    _authUser = null;
    _authState = AppAuthState.unauthenticated;
    _weatherState = WeatherLoadState.idle;
    _isAdmin = false;
    notifyListeners();
  }
}