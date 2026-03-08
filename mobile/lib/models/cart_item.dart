import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  final int quantity;
  final Product product;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  double get subtotal => product.price * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    int? quantity,
    Product? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    'product': product.toJson(),
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? 1,
      product: Product.fromJson(json['product'] ?? {}),
    );
  }
}
