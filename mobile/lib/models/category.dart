import '../constants/api_constants.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  final String? imageUrl;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.isActive = true,
  });

  Category copyWith({
    int? id,
    String? name,
    String? slug,
    String? imageUrl,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'image_url': imageUrl,
    'is_active': isActive,
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: ApiConstants.getFullImageUrl(json['image_url']),
      isActive: json['is_active'] ?? true,
    );
  }
}
