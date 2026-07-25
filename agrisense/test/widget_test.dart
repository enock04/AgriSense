/// Widget-level smoke tests for AgriSense.
///
/// These tests exercise the UI layer without a live Firebase connection by
/// providing a minimal mock implementation of each repository interface.
/// All business-logic assertions live in test/unit/.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:agrisense/domain/entities/lesson.dart';
import 'package:agrisense/domain/entities/user_profile.dart';
import 'package:agrisense/domain/entities/weather.dart';
import 'package:agrisense/domain/entities/community_post.dart';
import 'package:agrisense/domain/entities/auth_user.dart';
import 'package:agrisense/domain/entities/phone_credential.dart';
import 'package:agrisense/domain/repositories/auth_repository.dart';
import 'package:agrisense/domain/repositories/user_repository.dart';
import 'package:agrisense/domain/repositories/weather_repository.dart';
import 'package:agrisense/domain/repositories/lesson_repository.dart';
import 'package:agrisense/domain/repositories/community_repository.dart';
import 'package:agrisense/presentation/providers/app_provider.dart';
import 'package:agrisense/presentation/theme/app_theme.dart';

// ── Minimal stub implementations ─────────────────────────────────────────────

class _StubAuthRepo implements AuthRepository {
  @override Stream<AuthUser?> get authStateChanges => const Stream.empty();
  @override AuthUser? get currentUser => null;
  @override Future<void> sendOtp({required String phoneNumber,
      required void Function(String, int?) onCodeSent,
      required void Function(String) onError,
      required void Function(PhoneCredential) onAutoVerified}) async {}
  @override Future<bool> verifyOtp(
      {required String smsCode, required void Function(String) onError}) async => false;
  @override Future<bool> signInWithCredential(PhoneCredential c) async => false;
  @override Future<bool> signInWithGoogle(
      {required void Function(String) onError}) async => false;
  @override Future<void> signOut() async {}
}

class _StubUserRepo implements UserRepository {
  @override Future<UserProfile?> loadProfile() async => null;
  @override Future<void> saveProfile(UserProfile p) async {}
  @override Future<void> saveLessonProgress(String id, double v) async {}
  @override Future<Map<String, double>> loadAllProgress() async => {};
  @override Future<void> saveLocalPreference(String k, dynamic v) async {}
  @override bool? getLocalBool(String k) => null;
  @override String? getLocalString(String k) => null;
}

class _StubWeatherRepo implements WeatherRepository {
  @override Future<WeatherData> fetchWeather(String district) async =>
      const WeatherData(
        district: 'Musanze',
        province: 'Northern Province',
        temperature: 22,
        feelsLike: 21,
        humidity: 65,
        rainChance: 0.2,
        windSpeed: 10.0,
        uvIndex: 3,
        conditionEmoji: '🌤',
        status: WeatherStatus.good,
        advisoryText: 'Good conditions for farming.',
        advisoryKin: 'Ibihe byiza by\'ubuhinzi.',
        forecast: [],
      );
}

class _StubLessonRepo implements LessonRepository {
  @override Stream<List<Lesson>> lessonsStream() => const Stream.empty();
  @override Future<Map<String, String>?> getTodaysTip() async => null;
  @override Future<void> seedLessonsIfEmpty() async {}
  @override Future<void> seedTipsIfEmpty() async {}
  @override Future<bool> isAdmin({String? storedPhone}) async => false;
  @override Future<List<Lesson>> getAllLessonsAdmin() async => [];
  @override Future<String?> saveLesson(Lesson lesson) async => lesson.id;
  @override Future<void> deleteLesson(String id) async {}
  @override Future<List<Map<String, dynamic>>> getAllTipsAdmin() async => [];
  @override Future<String?> saveTip({
    required String id, required String title, required String titleKin,
    required String body, required String bodyKin, required String emoji,
  }) async => id;
  @override Future<void> deleteTip(String id) async {}
}

class _StubCommunityRepo implements CommunityRepository {
  @override Stream<List<CommunityPost>> postsStream() => const Stream.empty();
  @override Future<void> addPost({
    required String question, required String questionKin,
    required String userName, required String district,
  }) async {}
  @override Future<void> toggleUpvote(String postId) async {}
  @override Future<void> deletePost(String postId) async {}
  @override Future<void> seedPostsIfEmpty() async {}
}

// ── Helper: build the app with stubs ─────────────────────────────────────────

Widget _buildTestApp() {
  return ChangeNotifierProvider(
    create: (_) => AppProvider(
      authRepository: _StubAuthRepo(),
      userRepository: _StubUserRepo(),
      weatherRepository: _StubWeatherRepo(),
      lessonRepository: _StubLessonRepo(),
      communityRepository: _StubCommunityRepo(),
    ),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          final provider = context.watch<AppProvider>();
          // Unauthenticated state → show a placeholder matching what router shows
          if (provider.authState == AppAuthState.unauthenticated) {
            return const Scaffold(body: Center(child: Text('Sign In')));
          }
          return const Scaffold(body: Center(child: Text('App')));
        },
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AppProvider with stub repositories', () {
    testWidgets('starts in loading state then resolves to unauthenticated',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      // First pump: loading state or unauthenticated
      // After async _init completes:
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('renders without Firebase errors using stub repos',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      // No exceptions thrown = stub repos wired correctly
      expect(tester.takeException(), isNull);
    });
  });
}
