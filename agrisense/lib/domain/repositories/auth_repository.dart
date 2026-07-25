import '../entities/auth_user.dart';
import '../entities/phone_credential.dart';

/// Contract for authentication operations (phone OTP + Google).
abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneCredential credential) onAutoVerified,
  });

  /// Verifies a manually-entered SMS code. Returns true on success.
  Future<bool> verifyOtp({
    required String smsCode,
    required void Function(String error) onError,
  });

  /// Signs in with a credential obtained via auto-verification. Returns true on success.
  Future<bool> signInWithCredential(PhoneCredential credential);

  /// Returns true on success, false if the user cancelled.
  Future<bool> signInWithGoogle({required void Function(String error) onError});

  Future<void> signOut();
}
