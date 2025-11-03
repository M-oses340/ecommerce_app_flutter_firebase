class UserModel {
  final String id;
  final String name;
  final String email;
  final String address;
  final String phone;
  final String? profileImage; // ✅ optional field

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    this.profileImage,
  });

  // ✅ Convert Firestore JSON to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'], // optional, no crash if missing
    );
  }

  // ✅ Convert UserModel to JSON (for writing to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      if (profileImage != null) 'profileImage': profileImage, // only include if set
    };
  }
}
