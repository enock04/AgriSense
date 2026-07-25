import 'package:firebase_auth/firebase_auth.dart' show User, PhoneAuthCredential;
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/phone_credential.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';

/// Concrete implementation of [AuthRepository].
/// Delegates all raw Firebase calls to [AuthRemoteDatasource] and adapts
/// Firebase types to domain-level types — this is the only layer that
/// should ever import `firebase_auth` for authentication concerns.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  AuthUser? _toAuthUser(User? u) =>
      u == null ? null : AuthUser(uid: u.uid, phoneNumber: u.phoneNumber);

  @override
  Stream<AuthUser?> get authStateChanges =>
      _datasource.authStateChanges.map(_toAuthUser);

  @override
  AuthUser? get currentUser => _toAuthUser(_datasource.currentUser);

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String, int?) onCodeSent,
    required void Function(String) onError,
    required void Function(PhoneCredential) onAutoVerified,
  }) =>
      _datasource.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
        onAutoVerified: (PhoneAuthCredential c) => onAutoVerified(PhoneCredential(c)),
      );

  @override
  Future<bool> verifyOtp({
    required String smsCode,
    required void Function(String) onError,
  }) async {
    final result = await _datasource.verifyOtp(smsCode: smsCode, onError: onError);
    return result != null;
  }

  @override
  Future<bool> signInWithCredential(PhoneCredential credential) async {
    final result = await _datasource
        .signInWithPhoneCredential(credential.token as PhoneAuthCredential);
    return result != null;
  }

  @override
  Future<bool> signInWithGoogle({required void Function(String) onError}) async {
    final result = await _datasource.signInWithGoogle(onError: onError);
    return result != null;
  }

  @override
  Future<void> signOut() => _datasource.signOut();
}
