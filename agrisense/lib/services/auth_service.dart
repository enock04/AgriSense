import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Test credentials — DEBUG BUILDS ONLY ─────────────────────────────
  // In release builds these are empty strings so the bypass never triggers.
  static const String testPhone = kDebugMode ? '+250793442608' : '';
  static const String testCode  = kDebugMode ? '000000' : '';
  static const String _testPhone = testPhone;
  bool _testOtpSent = false;
  bool get isTestMode => _testOtpSent;

  String? _verificationId;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Send OTP ─────────────────────────────────────────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    final phone = phoneNumber.startsWith('+') ? phoneNumber : '+250$phoneNumber';

    // ── Test bypass ──────────────────────────────────────────────────────
    if (phone == _testPhone) {
      _testOtpSent = true;
      // Simulate a short delay like a real SMS
      await Future.delayed(const Duration(milliseconds: 800));
      onCodeSent('test-verification-id', null);
      return;
    }

    // ── Real Firebase OTP ────────────────────────────────────────────────
    _testOtpSent = false;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_friendlyError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError('Failed to send OTP. Please check your phone number.');
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<UserCredential?> verifyOtp({
    required String smsCode,
    required void Function(String error) onError,
  }) async {
    // ── Test bypass ──────────────────────────────────────────────────────
    if (_testOtpSent) {
      if (smsCode == testCode) {
        // Sign in anonymously as test user so Firebase auth state is set
        try {
          return await _auth.signInAnonymously();
        } catch (_) {
          // If anonymous sign-in fails (disabled), use a fake success path
          onError('Test mode: code accepted. Enable anonymous auth in Firebase or use real OTP.');
          return null;
        }
      } else {
        onError('Wrong code. Test number uses code: $testCode');
        return null;
      }
    }

    // ── Real Firebase verification ───────────────────────────────────────
    if (_verificationId == null) {
      onError('Session expired. Please request a new OTP.');
      return null;
    }
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      onError(_friendlyError(e.code));
      return null;
    } catch (e) {
      onError('Verification failed. Please try again.');
      return null;
    }
  }

  // ── Sign in with auto-verified credential (Android SMS auto-read) ─────────
  Future<UserCredential?> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (_) {
      return null;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ── Friendly error messages ───────────────────────────────────────────────
  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use format: +250 7XX XXX XXX';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      case 'invalid-verification-code':
        return 'Wrong code. Please check and try again.';
      case 'session-expired':
        return 'Code expired. Please request a new one.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}
