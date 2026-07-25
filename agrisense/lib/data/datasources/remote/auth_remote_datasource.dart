import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// All raw Firebase Auth + Google Sign-In calls.
/// No business logic — only data access.
class AuthRemoteDatasource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Test credentials (debug builds only) ────────────────────────────────
  static const String _testPhone = kDebugMode ? '+250793442608' : '';
  static const String _testCode  = kDebugMode ? '000000'        : '';

  bool _testOtpSent = false;
  String? _verificationId;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Phone OTP ────────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String, int?) onCodeSent,
    required void Function(String) onError,
    required void Function(PhoneAuthCredential) onAutoVerified,
  }) async {
    final phone = phoneNumber.startsWith('+') ? phoneNumber : '+250$phoneNumber';

    // Test bypass (debug only)
    if (phone == _testPhone) {
      _testOtpSent = true;
      await Future.delayed(const Duration(milliseconds: 800));
      onCodeSent('test-verification-id', null);
      return;
    }

    _testOtpSent = false;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: onAutoVerified,
        verificationFailed: (e) => onError(_friendlyError(e.code)),
        codeSent: (id, token) { _verificationId = id; onCodeSent(id, token); },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
    } catch (_) {
      onError('Failed to send OTP. Check your phone number.');
    }
  }

  Future<UserCredential?> verifyOtp({
    required String smsCode,
    required void Function(String) onError,
  }) async {
    // Test bypass
    if (_testOtpSent) {
      if (smsCode == _testCode) {
        try { return await _auth.signInAnonymously(); }
        catch (_) { onError('Enable anonymous auth in Firebase.'); return null; }
      }
      onError('Wrong code. Test number uses: $_testCode');
      return null;
    }

    if (_verificationId == null) {
      onError('Session expired. Request a new OTP.');
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
    } catch (_) {
      onError('Verification failed. Please try again.');
      return null;
    }
  }

  Future<UserCredential?> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try { return await _auth.signInWithCredential(credential); }
    catch (_) { return null; }
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle({
    required void Function(String) onError,
  }) async {
    try {
      // Trigger the Google authentication flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        onError('Sign-in cancelled.');
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      onError(_friendlyError(e.code));
      return null;
    } catch (e) {
      onError('Google sign-in failed. Please try again.');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Friendly error messages ──────────────────────────────────────────────
  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-phone-number':       return 'Invalid phone number.';
      case 'too-many-requests':          return 'Too many attempts. Wait a few minutes.';
      case 'invalid-verification-code':  return 'Wrong code. Please check and try again.';
      case 'session-expired':            return 'Code expired. Request a new one.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default: return 'Something went wrong ($code). Please try again.';
    }
  }
}
