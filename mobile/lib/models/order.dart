import '../constants/api_constants.dart';

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String? note;
  final String? createdAt;
  final String? cancelledAt;
  final String? deliveredAt;
  final List<OrderItem> items;
  final OrderAddress? shippingAddress;
  final OrderCustomer? customer;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    this.shippingFee = 0,
    required this.total,
    this.note,
    this.createdAt,
    this.cancelledAt,
    this.deliveredAt,
    this.items = const [],
    this.shippingAddress,
    this.customer,
  });

  bool get canCancel => status == 'pending' || status == 'confirmed';

  String get statusText {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'preparing': return 'Đang chuẩn bị';
      case 'shipping': return 'Đang giao hàng';
      case 'delivered': return 'Đã giao hàng';
      case 'failed_delivery': return 'Giao thất bại';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?) ?? [];
    final addressMap = json['shippingAddress'] as Map<String, dynamic>?;
    final customerMap = json['customer'] as Map<String, dynamic>?;

    return Order(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'cod',
      paymentStatus: json['payment_status'] ?? 'pending',
      subtotal: _parseDouble(json['subtotal']),
      shippingFee: _parseDouble(json['shipping_fee']),
      total: _parseDouble(json['total']),
      note: json['note'],
      createdAt: json['createdAt'] ?? json['created_at'],
      cancelledAt: json['cancelled_at'],
      deliveredAt: json['delivered_at'],
      items: itemsList.map((e) => OrderItem.fromJson(e)).toList(),
      shippingAddress: addressMap != null ? OrderAddress.fromJson(addressMap) : null,
      customer: customerMap != null ? OrderCustomer.fromJson(customerMap) : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double subtotal;
  final String? productImageUrl;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.subtotal,
    this.productImageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return OrderItem(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      productPrice: Order._parseDouble(json['product_price']),
      quantity: json['quantity'] ?? 0,
      subtotal: Order._parseDouble(json['subtotal']),
      productImageUrl: ApiConstants.getFullImageUrl(product?['image_url']),
    );
  }
}

class OrderAddress {
  final String recipientName;
  final String phone;
  final String addressLine;
  final String? ward;
  final String? district;
  final String city;

  OrderAddress({
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    this.ward,
    this.district,
    required this.city,
  });

  String get fullAddress {
    final parts = <String>[addressLine];
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    parts.add(city);
    return parts.join(', ');
  }

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['address_line'] ?? '',
      ward: json['ward'],
      district: json['district'],
      city: json['city'] ?? '',
    );
  }
}

class OrderCustomer {
  final String id;
  final String name;
  final String phone;
  final String? email;

  OrderCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }
}
