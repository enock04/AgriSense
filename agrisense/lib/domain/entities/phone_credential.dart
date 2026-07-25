/// Opaque credential produced by platform-level phone auto-verification
/// (e.g. Android's automatic SMS retrieval). The domain and presentation
/// layers only ever pass this through — they never inspect its contents.
class PhoneCredential {
  final Object token;

  const PhoneCredential(this.token);
}
