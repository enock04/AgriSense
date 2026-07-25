import 'crop.dart';
import 'farmer_type.dart';

/// Domain entity representing a farmer's profile.
class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final FarmerType farmerType;
  final List<Crop> selectedCrops;
  final String district;
  final String language;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.farmerType,
    required this.selectedCrops,
    required this.district,
    required this.language,
  });

  UserProfile copyWith({
    String? name,
    String? phone,
    FarmerType? farmerType,
    List<Crop>? selectedCrops,
    String? district,
    String? language,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      farmerType: farmerType ?? this.farmerType,
      selectedCrops: selectedCrops ?? this.selectedCrops,
      district: district ?? this.district,
      language: language ?? this.language,
    );
  }
}
