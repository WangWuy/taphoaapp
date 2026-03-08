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

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'avatar_url': avatarUrl,
    'is_active': isActive,
  };

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
