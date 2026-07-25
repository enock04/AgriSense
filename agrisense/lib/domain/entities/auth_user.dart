/// Minimal domain representation of the signed-in auth user.
class AuthUser {
  final String uid;
  final String? phoneNumber;

  const AuthUser({required this.uid, this.phoneNumber});
}
