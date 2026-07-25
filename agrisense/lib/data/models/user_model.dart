import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/farmer_type.dart';
import '../../domain/entities/user_profile.dart';

/// Firestore DTO for a user profile document.
/// Responsible for serialisation / deserialisation only — no business logic.
class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String farmerType;
  final List<Map<String, String>> crops;
  final String district;
  final String language;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.farmerType,
    required this.crops,
    required this.district,
    required this.language,
  });

  // ── Firestore → model ────────────────────────────────────────────────────
  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    final rawCrops = data['crops'] as List? ?? [];
    return UserModel(
      uid: uid,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      farmerType: data['farmerType'] as String? ?? 'farmer',
      crops: rawCrops
          .map((c) => Map<String, String>.from(c as Map))
          .toList(),
      district: data['district'] as String? ?? '',
      language: data['language'] as String? ?? 'rw',
    );
  }

  // ── model → Firestore ────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'phone': phone,
    'farmerType': farmerType,
    'crops': crops,
    'district': district,
    'language': language,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // ── model → domain entity ─────────────────────────────────────────────
  UserProfile toEntity() => UserProfile(
    uid: uid,
    name: name,
    phone: phone,
    farmerType: FarmerType.values.firstWhere(
      (e) => e.name == farmerType,
      orElse: () => FarmerType.farmer,
    ),
    selectedCrops: crops
        .map((c) => Crop(
              id: c['id'] ?? '',
              name: c['name'] ?? '',
              kinyarwanda: c['kinyarwanda'] ?? '',
              emoji: c['emoji'] ?? '',
            ))
        .toList(),
    district: district,
    language: language,
  );

  // ── domain entity → model ─────────────────────────────────────────────
  factory UserModel.fromEntity(UserProfile profile) => UserModel(
    uid: profile.uid,
    name: profile.name,
    phone: profile.phone,
    farmerType: profile.farmerType.name,
    crops: profile.selectedCrops
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'kinyarwanda': c.kinyarwanda,
              'emoji': c.emoji,
            })
        .toList(),
    district: profile.district,
    language: profile.language,
  );
}
