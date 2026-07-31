/// Contract for push-notification permission, topic subscription, and
/// device-token registration. No Firebase/FCM types leak past this layer.
abstract class NotificationRepository {
  /// Registers foreground/background message handling. Call once at startup,
  /// before any permission is requested.
  Future<void> initialize();

  /// True if the OS has already granted notification permission — never
  /// shows a system prompt.
  Future<bool> hasPermission();

  /// Shows the OS permission prompt if not already decided. Returns true if
  /// the user grants permission.
  Future<bool> requestPermission();

  /// Subscribes to weather-alert and general-announcement topics for
  /// [district] so alerts can be broadcast from the Firebase Console without
  /// any backend code.
  Future<void> subscribeToAlerts(String district);

  /// Unsubscribes from the alert topics for [district].
  Future<void> unsubscribeFromAlerts(String district);

  /// Persists this device's current FCM token against [uid] so a future
  /// backend could target this specific user.
  Future<void> syncTokenForUser(String uid);
}
