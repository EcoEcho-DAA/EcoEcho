class UserModel {
  final int id;
  final String username;
  final String email;
  final int totalXp;
  final String? city;
  final String? province;
  final int? currentTierId;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.totalXp,
    this.city,
    this.province,
    this.currentTierId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      totalXp: json['total_xp'] as int,
      city: json['city'] as String?,
      province: json['province'] as String?,
      currentTierId: json['current_tier_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'total_xp': totalXp,
      'city': city,
      'province': province,
      'current_tier_id': currentTierId,
    };
  }
}