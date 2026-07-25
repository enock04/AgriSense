import 'package:flutter/material.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/phone_credential.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth state managed as a simple enum for routing.
enum AppAuthState { loading, unauthenticated, needsProfile, ready }

/// Manages Firebase authentication state.
/// Business logic: none — routes based on auth changes only.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository) {
    _authRepository.authStateChanges.listen(_onAuthChanged);
    // Immediately reflect cached auth state
    _onAuthChanged(_authRepository.currentUser);
  }

  AppAuthState _authState = AppAuthState.loading;
  AppAuthState get authState => _authState;

  AuthUser? _user;
  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;

  bool _profileLoaded = false;

  /// Called by ProfileProvider after it successfully loads/saves a profile.
  void markProfileReady() {
    _profileLoaded = true;
    if (_user != null) {
      _authState = AppAuthState.ready;
      notifyListeners();
    }
  }

  void _onAuthChanged(AuthUser? user) {
    _user = user;
    if (user == null) {
      _authState = AppAuthState.unauthenticated;
      _profileLoaded = false;
    } else {
      _authState = _profileLoaded
          ? AppAuthState.ready
          : AppAuthState.needsProfile;
    }
    notifyListeners();
  }

  // ── OTP Sign-In ──────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String, int?) onCodeSent,
    required void Function(String) onError,
    required void Function(PhoneCredential) onAutoVerified,
  }) =>
      _authRepository.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
        onAutoVerified: onAutoVerified,
      );

  Future<bool> verifyOtp({
    required String smsCode,
    required void Function(String) onError,
  }) =>
      _authRepository.verifyOtp(smsCode: smsCode, onError: onError);

  Future<bool> signInWithCredential(PhoneCredential credential) =>
      _authRepository.signInWithCredential(credential);

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle({
    required void Function(String) onError,
  }) =>
      _authRepository.signInWithGoogle(onError: onError);

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authRepository.signOut();
    _profileLoaded = false;
  }
}
