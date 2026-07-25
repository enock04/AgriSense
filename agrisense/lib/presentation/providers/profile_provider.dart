import 'package:flutter/material.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/farmer_type.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import 'auth_provider.dart';

/// Manages the current farmer's profile.
/// Business logic: profile persistence + local caching.
class ProfileProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final AuthProvider _authProvider;

  ProfileProvider(this._userRepository, this._authProvider);

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool get hasProfile => _profile != null;

  String get farmerName => _profile?.name ?? '';
  String get phone      => _profile?.phone ?? '';
  String get district   => _profile?.district ?? '';
  String get language   => _profile?.language ?? 'rw';
  FarmerType get farmerType => _profile?.farmerType ?? FarmerType.farmer;
  List<Crop> get selectedCrops => _profile?.selectedCrops ?? [];

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    try {
      final uid = _authProvider.user?.uid ?? '';
      final loaded = await _userRepository.loadProfile();
      if (loaded != null) {
        // Inject real uid
        _profile = UserProfile(
          uid: uid,
          name: loaded.name,
          phone: loaded.phone,
          farmerType: loaded.farmerType,
          selectedCrops: loaded.selectedCrops,
          district: loaded.district,
          language: loaded.language,
        );
        _authProvider.markProfileReady();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProfileProvider.loadProfile failed: $e');
    }
  }

  // ── Save (Onboarding complete / profile update) ───────────────────────────

  Future<void> saveProfile({
    required String name,
    required String phone,
    required FarmerType farmerType,
    required List<Crop> crops,
    required String district,
    required String language,
  }) async {
    final uid = _authProvider.user?.uid ?? '';
    final newProfile = UserProfile(
      uid: uid,
      name: name,
      phone: phone,
      farmerType: farmerType,
      selectedCrops: crops,
      district: district,
      language: language,
    );
    _profile = newProfile;
    notifyListeners();

    await _userRepository.saveProfile(newProfile);
    _authProvider.markProfileReady();
  }

  // ── Individual field updates ───────────────────────────────────────────────

  Future<void> updateLanguage(String lang) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(language: lang);
    notifyListeners();
    await _userRepository.saveProfile(_profile!);
  }

  Future<void> updateDistrict(String district) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(district: district);
    notifyListeners();
    await _userRepository.saveProfile(_profile!);
  }

  Future<void> updateName(String name) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(name: name);
    notifyListeners();
    await _userRepository.saveProfile(_profile!);
  }

  void setAdminStatus(bool isAdmin) {
    _isAdmin = isAdmin;
    notifyListeners();
  }

  void reset() {
    _profile = null;
    _isAdmin = false;
    notifyListeners();
  }
}
