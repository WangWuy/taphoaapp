import '../constants/api_constants.dart';

class Product {
  final String id;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final double? costPrice;
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
    this.costPrice,
    this.unit = 'cái',
    this.stockQuantity = 0,
    this.imageUrl,
    this.isActive = true,
    this.categoryName,
  });

  bool get isOnSale =>
      compareAtPrice != null && compareAtPrice! > 0 && compareAtPrice! < price;

  int get discountPercent {
    if (!isOnSale) return 0;
    return ((1 - compareAtPrice! / price) * 100).round();
  }

  /// The price customer actually pays (sale price if on sale, otherwise regular price)
  double get sellingPrice => isOnSale ? compareAtPrice! : price;

  Product copyWith({
    String? id,
    int? categoryId,
    String? name,
    String? description,
    double? price,
    double? compareAtPrice,
    double? costPrice,
    String? unit,
    int? stockQuantity,
    String? imageUrl,
    bool? isActive,
    String? categoryName,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      compareAtPrice: compareAtPrice ?? this.compareAtPrice,
      costPrice: costPrice ?? this.costPrice,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price': price,
    'compare_at_price': compareAtPrice,
    'cost_price': costPrice,
    'unit': unit,
    'stock_quantity': stockQuantity,
    'image_url': imageUrl,
    'is_active': isActive,
  };

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
      costPrice: json['cost_price'] != null
          ? (json['cost_price'] is int)
              ? (json['cost_price'] as int).toDouble()
              : double.tryParse(json['cost_price'].toString())
          : null,
      unit: json['unit'] ?? 'cái',
      stockQuantity: json['stock_quantity'] ?? 0,
      imageUrl: ApiConstants.getFullImageUrl(json['image_url']),
      isActive: json['is_active'] ?? true,
      categoryName: category?['name'],
    );
  }
}
