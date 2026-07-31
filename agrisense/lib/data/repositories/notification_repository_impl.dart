import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote/notification_remote_datasource.dart';
import '../datasources/remote/firestore_remote_datasource.dart';

/// Concrete implementation of [NotificationRepository].
/// Coordinates FCM/local-notifications (device) with Firestore (token storage).
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource _remote;
  final FirestoreRemoteDatasource _firestore;

  NotificationRepositoryImpl(this._remote, this._firestore);

  @override
  Future<void> initialize() => _remote.initialize();

  @override
  Future<bool> hasPermission() => _remote.hasPermission();

  @override
  Future<bool> requestPermission() => _remote.requestPermission();

  @override
  Future<void> subscribeToAlerts(String district) => _remote.subscribeToAlerts(district);

  @override
  Future<void> unsubscribeFromAlerts(String district) => _remote.unsubscribeFromAlerts(district);

  @override
  Future<void> syncTokenForUser(String uid) async {
    final token = await _remote.getToken();
    if (token != null) await _firestore.saveFcmToken(uid, token);
  }
}
