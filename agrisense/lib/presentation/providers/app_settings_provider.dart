import 'package:flutter/material.dart';
import '../../data/datasources/local/preferences_local_datasource.dart';

/// Manages app-wide user preferences (language, notifications, offline mode).
/// All values are persisted to SharedPreferences via [PreferencesLocalDatasource].
class AppSettingsProvider extends ChangeNotifier {
  final PreferencesLocalDatasource _local;

  AppSettingsProvider(this._local);

  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

  String _language = 'rw';
  String get language => _language;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _offlineDownloadEnabled = false;
  bool get offlineDownloadEnabled => _offlineDownloadEnabled;

  /// Load all saved preferences on startup.
  Future<void> load() async {
    _language              = _local.getString('language')     ?? 'rw';
    _notificationsEnabled  = _local.getBool('notifications')  ?? true;
    _offlineDownloadEnabled= _local.getBool('offlineDownload')??false;
    notifyListeners();
  }

  // ── Tab navigation ────────────────────────────────────────────────────────

  void navigateToTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // ── Language ──────────────────────────────────────────────────────────────

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _local.setString('language', lang);
    notifyListeners();
  }

  // ── Notification toggle ───────────────────────────────────────────────────

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    await _local.setBool('notifications', value);
    notifyListeners();
  }

  // ── Offline download toggle ───────────────────────────────────────────────

  Future<void> setOfflineDownload(bool value) async {
    _offlineDownloadEnabled = value;
    await _local.setBool('offlineDownload', value);
    notifyListeners();
  }
}
