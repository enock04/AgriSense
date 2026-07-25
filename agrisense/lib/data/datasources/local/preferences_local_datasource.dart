import 'package:shared_preferences/shared_preferences.dart';

/// Wraps SharedPreferences — the only class in the app that touches
/// SharedPreferences directly. All other layers go through this.
class PreferencesLocalDatasource {
  late SharedPreferences _prefs;

  /// Must be called once before any other method (e.g. in main()).
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  String?  getString(String key)  => _prefs.getString(key);
  bool?    getBool(String key)    => _prefs.getBool(key);
  double?  getDouble(String key)  => _prefs.getDouble(key);
  int?     getInt(String key)     => _prefs.getInt(key);

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> setBool(String key, bool value) =>
      _prefs.setBool(key, value);

  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  Future<void> setInt(String key, int value) =>
      _prefs.setInt(key, value);

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clear() => _prefs.clear();

  Future<void> remove(String key) => _prefs.remove(key);
}
