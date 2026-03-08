import '../constants/api_constants.dart';

class Product {
  final String id;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final String unit;
  final int stockQuantity;
  final String? imageUrl;
  final bool isActive;
  final String? categoryName;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.unit = 'cái',
    this.stockQuantity = 0,
    this.imageUrl,
    this.isActive = true,
    this.categoryName,
  });

  bool get isOnSale =>
      compareAtPrice != null && compareAtPrice! > price;

  int get discountPercent {
    if (!isOnSale) return 0;
    return ((1 - price / compareAtPrice!) * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] ?? '',
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      compareAtPrice: json['compare_at_price'] != null
          ? (json['compare_at_price'] is int)
              ? (json['compare_at_price'] as int).toDouble()
              : double.tryParse(json['compare_at_price'].toString())
          : null,
      unit: json['unit'] ?? 'cái',
      stockQuantity: json['stock_quantity'] ?? 0,
      imageUrl: ApiConstants.getFullImageUrl(json['image_url']),
      isActive: json['is_active'] ?? true,
      categoryName: category?['name'],
    );
  }
}
