class User {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String role;
  final String? avatarUrl;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}
