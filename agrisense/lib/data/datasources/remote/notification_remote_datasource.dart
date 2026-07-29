import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Raw FCM + local-notification plumbing. No business logic — only the
/// mechanics of requesting permission, subscribing to topics, and showing a
/// notification while the app is in the foreground (FCM does not surface
/// foreground "notification" payloads on its own).
class NotificationRemoteDatasource {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'weather_alerts';
  static const String _channelName = 'Weather & Community Alerts';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Severe weather warnings and community updates',
          importance: Importance.high,
        ));

    // Foreground messages aren't shown by the OS automatically — display
    // them ourselves via the local-notifications plugin.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId, _channelName,
            importance: Importance.high, priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// FCM topic names only allow [a-zA-Z0-9-_.~%] — sanitise free-text input.
  String _topicSafe(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

  Future<void> subscribeToAlerts(String district) async {
    await _messaging.subscribeToTopic('weather_alerts_all');
    if (district.isNotEmpty) {
      await _messaging.subscribeToTopic('weather_alerts_${_topicSafe(district)}');
    }
  }

  Future<void> unsubscribeFromAlerts(String district) async {
    await _messaging.unsubscribeFromTopic('weather_alerts_all');
    if (district.isNotEmpty) {
      await _messaging.unsubscribeFromTopic('weather_alerts_${_topicSafe(district)}');
    }
  }

  Future<String?> getToken() => _messaging.getToken();
}
