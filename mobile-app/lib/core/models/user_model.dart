class UserModel {
  final String id;
  final String email;
  final String role; // 'client' | 'sales' | 'engineer'
  final String? fullName;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isClient => role == 'client';
  bool get isSales => role == 'sales';
  bool get isEngineer => role == 'engineer';
}

