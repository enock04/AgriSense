import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// ── Clean Architecture: Data Layer ──────────────────────────────────────────
import 'data/datasources/local/preferences_local_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/firestore_remote_datasource.dart';
import 'data/datasources/remote/notification_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/weather_repository_impl.dart';
import 'data/repositories/lesson_repository_impl.dart';
import 'data/repositories/community_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/datasources/remote/weather_remote_datasource.dart';

// ── Clean Architecture: Presentation Layer ──────────────────────────────────
import 'presentation/providers/app_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/shell/main_shell.dart';

/// Handles FCM messages received while the app is backgrounded/terminated.
/// Must be a top-level (or static) function — it runs in its own isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env is git-ignored)
  await dotenv.load(fileName: '.env');

  // Initialise Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialise local data source (SharedPreferences)
  final prefsLocal = PreferencesLocalDatasource();
  await prefsLocal.init();

  // ── Assemble the dependency graph ────────────────────────────────────────
  //   Data Sources
  final authRemote         = AuthRemoteDatasource();
  final firestoreRemote    = FirestoreRemoteDatasource();
  final weatherRemote      = WeatherRemoteDatasource();
  final notificationRemote = NotificationRemoteDatasource();

  //   Repositories (domain interfaces → concrete implementations)
  final authRepo         = AuthRepositoryImpl(authRemote);
  final userRepo         = UserRepositoryImpl(firestoreRemote, prefsLocal);
  final weatherRepo      = WeatherRepositoryImpl(weatherRemote);
  final lessonRepo       = LessonRepositoryImpl(firestoreRemote, prefsLocal);
  final communityRepo    = CommunityRepositoryImpl(firestoreRemote);
  final notificationRepo = NotificationRepositoryImpl(notificationRemote, firestoreRemote);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        /// AppProvider is the presentation-layer coordinator.
        /// Internally it depends only on domain repository interfaces —
        /// no direct Firebase or Firestore calls from the UI layer.
        ChangeNotifierProvider(
          create: (_) => AppProvider(
            authRepository:         authRepo,
            userRepository:         userRepo,
            weatherRepository:      weatherRepo,
            lessonRepository:       lessonRepo,
            communityRepository:    communityRepo,
            notificationRepository: notificationRepo,
          ),
        ),
      ],
      child: const AgriSenseApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root Application Widget
// ─────────────────────────────────────────────────────────────────────────────

class AgriSenseApp extends StatelessWidget {
  const AgriSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRouter(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Router — maps auth state to correct screen (no business logic here)
// ─────────────────────────────────────────────────────────────────────────────

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    switch (provider.authState) {
      case AppAuthState.loading:
        return const _SplashLoader();
      case AppAuthState.unauthenticated:
        return const OnboardingScreen();
      case AppAuthState.needsProfile:
        // Re-enter onboarding at the profile-setup step
        return const OnboardingScreen();
      case AppAuthState.ready:
        return const MainShell();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash loader shown while Firebase initialises
// ─────────────────────────────────────────────────────────────────────────────

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A5C35),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🌱', style: TextStyle(fontSize: 64)),
          SizedBox(height: 24),
          Text('AgriSense',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          SizedBox(height: 32),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Colors.white70, strokeWidth: 2.5),
          ),
        ]),
      ),
    );
  }
}
