import 'package:flutter_test/flutter_test.dart';
import 'package:agrisense/domain/entities/user_profile.dart';
import 'package:agrisense/domain/entities/farmer_type.dart';
import 'package:agrisense/domain/entities/crop.dart';

void main() {
  group('UserProfile entity', () {
    final maize = Crop(id: 'maize', name: 'Maize', kinyarwanda: 'Ibigori', emoji: '🌽');
    final beans = Crop(id: 'beans', name: 'Beans', kinyarwanda: 'Ibishyimbo', emoji: '🫘');

    final profile = UserProfile(
      uid: 'uid-001',
      name: 'Jean Claude',
      phone: '+250788123456',
      farmerType: FarmerType.farmer,
      selectedCrops: [maize, beans],
      district: 'Musanze',
      language: 'rw',
    );

    test('stores all fields correctly', () {
      expect(profile.uid, 'uid-001');
      expect(profile.name, 'Jean Claude');
      expect(profile.phone, '+250788123456');
      expect(profile.farmerType, FarmerType.farmer);
      expect(profile.selectedCrops, hasLength(2));
      expect(profile.district, 'Musanze');
      expect(profile.language, 'rw');
    });

    test('copyWith updates only specified fields', () {
      final updated = profile.copyWith(name: 'Amina', district: 'Kigali');
      expect(updated.name, 'Amina');
      expect(updated.district, 'Kigali');
      // unchanged fields preserved
      expect(updated.uid, 'uid-001');
      expect(updated.phone, '+250788123456');
      expect(updated.farmerType, FarmerType.farmer);
      expect(updated.language, 'rw');
    });

    test('copyWith with no arguments returns identical values', () {
      final copy = profile.copyWith();
      expect(copy.uid, profile.uid);
      expect(copy.name, profile.name);
      expect(copy.phone, profile.phone);
      expect(copy.district, profile.district);
      expect(copy.language, profile.language);
    });

    test('copyWith can switch farmerType', () {
      final trader = profile.copyWith(farmerType: FarmerType.trader);
      expect(trader.farmerType, FarmerType.trader);
    });

    test('copyWith can update selectedCrops', () {
      final sorghum = Crop(id: 'sorghum', name: 'Sorghum', kinyarwanda: 'Amabira', emoji: '🌾');
      final updated = profile.copyWith(selectedCrops: [sorghum]);
      expect(updated.selectedCrops, hasLength(1));
      expect(updated.selectedCrops.first.id, 'sorghum');
    });
  });

  group('FarmerType enum', () {
    test('has three values', () {
      expect(FarmerType.values, hasLength(3));
    });

    test('name lookup works for all variants', () {
      for (final ft in FarmerType.values) {
        final found = FarmerType.values.firstWhere((e) => e.name == ft.name);
        expect(found, ft);
      }
    });
  });

  group('Crop entity', () {
    test('stores all fields', () {
      final c = Crop(id: 'rice', name: 'Rice', kinyarwanda: 'Umuceri', emoji: '🍚');
      expect(c.id, 'rice');
      expect(c.name, 'Rice');
      expect(c.kinyarwanda, 'Umuceri');
      expect(c.emoji, '🍚');
    });
  });
}
