import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../services/weather_service.dart';
import '../services/firestore_service.dart';

enum WeatherLoadState { idle, loading, loaded, error }

/// Tracks the overall auth + profile state for routing.
enum AppAuthState {
  loading,          // still initialising
  unauthenticated,  // not logged in → show splash/onboarding
  needsProfile,     // logged in via phone but no Firestore profile yet → show profile setup
  ready,            // logged in + profile complete → show main app
}

class AppProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final FirestoreService _firestoreService = FirestoreService();

  // ── Tab navigation ───────────────────────────────────────────────────────
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  void navigateToTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // ── Auth & routing state ─────────────────────────────────────────────────
  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;

  AppAuthState _authState = AppAuthState.loading;
  AppAuthState get authState => _authState;

  // ── Onboarding ──────────────────────────────────────────────────────────
  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  // ── Language ────────────────────────────────────────────────────────────
  String _language = 'en';
  String get language => _language;

  // ── Farmer Profile ──────────────────────────────────────────────────────
  FarmerType _farmerType = FarmerType.farmer;
  FarmerType get farmerType => _farmerType;

  String _farmerName = '';
  String get farmerName => _farmerName;

  String _phone = '';
  String get phone => _phone;

  // ── Crops ───────────────────────────────────────────────────────────────
  final List<Crop> _selectedCrops = [];
  List<Crop> get selectedCrops => List.unmodifiable(_selectedCrops);

  // ── District ────────────────────────────────────────────────────────────
  String _district = '';
  String get district => _district;

  // ── Weather ─────────────────────────────────────────────────────────────
  WeatherData _currentWeather = MockData.goodWeather;
  WeatherData get currentWeather => _currentWeather;

  WeatherLoadState _weatherState = WeatherLoadState.idle;
  WeatherLoadState get weatherState => _weatherState;

  String _weatherError = '';
  String get weatherError => _weatherError;

  bool get isWeatherLoading => _weatherState == WeatherLoadState.loading;
  bool get showSevereWeather => _currentWeather.status == WeatherStatus.severe;

  // ── Lessons (from Firestore) ─────────────────────────────────────────────
  List<Lesson> _lessons = [];
  List<Lesson> get lessons => _lessons.isEmpty ? MockData.lessons : _lessons;
  bool _lessonsLoaded = false;
  bool get lessonsLoaded => _lessonsLoaded;

  // ── Today's tip (from Firestore) ─────────────────────────────────────────
  Map<String, String>? _todaysTip;
  Map<String, String> get todaysTip => _todaysTip ?? MockData.tipOfDay;

  // ── Admin ────────────────────────────────────────────────────────────────
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  // ── Lesson Progress ─────────────────────────────────────────────────────
  final Map<String, double> _lessonProgress = {};

  // ── Settings toggles ────────────────────────────────────────────────────
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _offlineDownloadEnabled = false;
  bool get offlineDownloadEnabled => _offlineDownloadEnabled;

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    notifyListeners();
  }

  Future<void> setOfflineDownload(bool value) async {
    _offlineDownloadEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offlineDownload', value);
    notifyListeners();
  }

  // ── Community upvotes (local cache) ─────────────────────────────────────
  final Set<String> _upvotedPosts = {};
  Set<String> get upvotedPosts => Set.unmodifiable(_upvotedPosts);

  // ── Firestore service (accessible by screens) ───────────────────────────
  FirestoreService get firestore => _firestoreService;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        // User is logged in — try to load profile
        await _loadFromFirestore();
        // After load, decide routing state
        _authState = _onboardingComplete ? AppAuthState.ready : AppAuthState.needsProfile;
      } else {
        // Not logged in
        _authState = AppAuthState.unauthenticated;
        _onboardingComplete = false;
      }
      notifyListeners();
    });

    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    _language = prefs.getString('language') ?? 'rw';
    _district = prefs.getString('district') ?? '';
    _farmerName = prefs.getString('farmerName') ?? '';
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    _offlineDownloadEnabled = prefs.getBool('offlineDownload') ?? false;

    // Load lesson progress from local cache
    for (final lesson in MockData.lessons) {
      _lessonProgress[lesson.id] =
          prefs.getDouble('progress_${lesson.id}') ?? lesson.progress;
    }

    // ── Fast initial routing (no network needed) ───────────────────────
    // currentUser is synchronous — immediately available from local cache.
    // Use it to decide routing right away instead of waiting for the stream.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _firebaseUser = currentUser;
      _authState = _onboardingComplete ? AppAuthState.ready : AppAuthState.needsProfile;
    } else {
      _authState = AppAuthState.unauthenticated;
    }
    notifyListeners();

    if (_district.isNotEmpty) await refreshWeather();
  }

  // ── Load profile from Firestore ──────────────────────────────────────────
  Future<void> _loadFromFirestore() async {
    try {
      final data = await _firestoreService.loadProfile();
      if (data != null) {
        _farmerName = data['name'] ?? _farmerName;
        _phone = data['phone'] ?? _phone;
        _district = data['district'] ?? _district;
        _language = data['language'] ?? _language;
        _onboardingComplete = true;

        final type = data['farmerType'] as String?;
        if (type != null) {
          _farmerType = FarmerType.values.firstWhere(
              (e) => e.name == type, orElse: () => FarmerType.farmer);
        }

        final cropsData = data['crops'] as List?;
        if (cropsData != null) {
          _selectedCrops
            ..clear()
            ..addAll(cropsData.map((c) => Crop(
                  id: c['id'] as String,
                  name: c['name'] as String,
                  kinyarwanda: c['kinyarwanda'] as String,
                  emoji: c['emoji'] as String,
                )));
        }

        // Load Firestore progress (overrides local)
        final progress = await _firestoreService.loadAllProgress();
        _lessonProgress.addAll(progress);

        // Persist locally too
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboardingComplete', true);
        await prefs.setString('farmerName', _farmerName);
        await prefs.setString('district', _district);
        await prefs.setString('language', _language);

        notifyListeners();

        if (_district.isNotEmpty) await refreshWeather();
      }
    } catch (_) {}
  }

  // ── Weather ─────────────────────────────────────────────────────────────

  // ── Load lessons from Firestore ──────────────────────────────────────────

  void _loadLessons() {
    _firestoreService.lessonsStream().listen((firestoreLessons) {
      if (firestoreLessons.isNotEmpty) {
        _lessons = firestoreLessons.map((ld) =>
            ld.toLesson(progress: _lessonProgress[ld.id] ?? 0.0)).toList();
        _lessonsLoaded = true;
        notifyListeners();
      }
    }, onError: (_) {
      // Fall back to mock data on error — already the default
    });
  }

  Future<void> _loadTip() async {
    final tip = await _firestoreService.getTodaysTip();
    if (tip != null) {
      _todaysTip = tip;
      notifyListeners();
    }
  }

  Future<void> _checkAdmin() async {
    _isAdmin = await _firestoreService.isAdmin();
    if (_isAdmin) notifyListeners();
  }

  // ── Weather ─────────────────────────────────────────────────────────────

  Future<void> refreshWeather() async {
    _weatherState = WeatherLoadState.loading;
    _weatherError = '';
    notifyListeners();

    try {
      final d = _district.isNotEmpty ? _district : 'Musanze';
      _currentWeather = await _weatherService.fetchWeather(d);
      _weatherState = WeatherLoadState.loaded;
    } catch (e) {
      _weatherError = 'Could not load weather. Showing last known data.';
      _weatherState = WeatherLoadState.error;
    }
    notifyListeners();
  }

  Future<void> selectDistrict(String d) async {
    _district = d;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('district', d);
    notifyListeners();
    await refreshWeather();
  }

  void toggleWeatherScenario() {
    _currentWeather = _currentWeather.status == WeatherStatus.good
        ? MockData.severeWeather
        : MockData.goodWeather;
    notifyListeners();
  }

  // ── Onboarding / Profile ─────────────────────────────────────────────────

  Future<void> completeOnboarding({
    required String name,
    required String phone,
    required FarmerType farmerType,
    required List<Crop> crops,
    required String district,
    required String language,
  }) async {
    _farmerName = name;
    _phone = phone;
    _farmerType = farmerType;
    _selectedCrops..clear()..addAll(crops);
    _district = district;
    _language = language;
    _onboardingComplete = true;

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    await prefs.setString('language', language);
    await prefs.setString('district', district);
    await prefs.setString('farmerName', name);

    // Save to Firestore
    await _firestoreService.saveProfile(
      name: name, phone: phone, farmerType: farmerType,
      crops: crops, district: district, language: language,
    );

    // Seed content on first launch (best effort — ok to fail)
    try { await _firestoreService.seedPostsIfEmpty(); } catch (_) {}
    try { await _firestoreService.seedLessonsIfEmpty(); } catch (_) {}
    try { await _firestoreService.seedTipsIfEmpty(); } catch (_) {}

    // Ready regardless of whether Firebase user is set (test mode works too)
    _authState = AppAuthState.ready;
    notifyListeners();
    await refreshWeather();
    _loadLessons();
    _loadTip();
    _checkAdmin();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    if (isAuthenticated) {
      await _firestoreService.saveProfile(
        name: _farmerName, phone: _phone, farmerType: _farmerType,
        crops: _selectedCrops, district: _district, language: lang,
      );
    }
    notifyListeners();
  }

  void setFarmerType(FarmerType type) {
    _farmerType = type;
    notifyListeners();
  }

  Future<void> setFarmerName(String name) async {
    _farmerName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farmerName', name);
    if (isAuthenticated) {
      await _firestoreService.saveProfile(
        name: name, phone: _phone, farmerType: _farmerType,
        crops: _selectedCrops, district: _district, language: _language,
      );
    }
    notifyListeners();
  }

  void toggleCrop(Crop crop) {
    if (_selectedCrops.any((c) => c.id == crop.id)) {
      _selectedCrops.removeWhere((c) => c.id == crop.id);
    } else {
      _selectedCrops.add(crop);
    }
    notifyListeners();
  }

  bool isCropSelected(Crop crop) => _selectedCrops.any((c) => c.id == crop.id);

  // ── Lesson Progress ──────────────────────────────────────────────────────

  double getLessonProgress(String lessonId) => _lessonProgress[lessonId] ?? 0.0;

  Future<void> updateLessonProgress(String lessonId, double progress) async {
    _lessonProgress[lessonId] = progress.clamp(0.0, 1.0);

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('progress_$lessonId', _lessonProgress[lessonId]!);

    // Sync to Firestore
    await _firestoreService.saveLessonProgress(lessonId, _lessonProgress[lessonId]!);

    notifyListeners();
  }

  // ── Community ────────────────────────────────────────────────────────────

  void toggleUpvote(String postId) {
    if (_upvotedPosts.contains(postId)) {
      _upvotedPosts.remove(postId);
    } else {
      _upvotedPosts.add(postId);
    }
    // Also update Firestore atomically (fire-and-forget is intentional for snappy UI)
    unawaited(_firestoreService.toggleUpvote(postId));
    notifyListeners();
  }

  bool isUpvoted(String postId) => _upvotedPosts.contains(postId);

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetOnboarding() async {
    await FirebaseAuth.instance.signOut();
    _onboardingComplete = false;
    _selectedCrops.clear();
    _district = '';
    _farmerName = '';
    _phone = '';
    _currentWeather = MockData.goodWeather;
    _weatherState = WeatherLoadState.idle;
    _lessonProgress.clear();
    _upvotedPosts.clear();
    _firebaseUser = null;
    _authState = AppAuthState.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
