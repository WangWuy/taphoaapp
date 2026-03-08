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
