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

  Order copyWith({
    String? id,
    String? orderNumber,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    double? subtotal,
    double? shippingFee,
    double? total,
    String? note,
    String? createdAt,
    String? cancelledAt,
    String? deliveredAt,
    List<OrderItem>? items,
    OrderAddress? shippingAddress,
    OrderCustomer? customer,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      total: total ?? this.total,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      customer: customer ?? this.customer,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'status': status,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'subtotal': subtotal,
    'shipping_fee': shippingFee,
    'total': total,
    'note': note,
    'created_at': createdAt,
    'cancelled_at': cancelledAt,
    'delivered_at': deliveredAt,
    'items': items.map((e) => e.toJson()).toList(),
  };

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

  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? productPrice,
    int? quantity,
    double? subtotal,
    String? productImageUrl,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      productImageUrl: productImageUrl ?? this.productImageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'product_price': productPrice,
    'quantity': quantity,
    'subtotal': subtotal,
  };

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

  OrderAddress copyWith({
    String? recipientName,
    String? phone,
    String? addressLine,
    String? ward,
    String? district,
    String? city,
  }) {
    return OrderAddress(
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toJson() => {
    'recipient_name': recipientName,
    'phone': phone,
    'address_line': addressLine,
    'ward': ward,
    'district': district,
    'city': city,
  };

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

  OrderCustomer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
  }) {
    return OrderCustomer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
  };

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }
}
