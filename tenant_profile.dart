class TenantProfile {
  const TenantProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.propertyName,
    required this.unitNumber,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String propertyName;
  final String unitNumber;

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    return TenantProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'PEMS User',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      propertyName: json['propertyName']?.toString() ?? 'Property',
      unitNumber: json['unitNumber']?.toString() ?? 'Room',
    );
  }
}
