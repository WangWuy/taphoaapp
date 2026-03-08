class Address {
  final String id;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String? ward;
  final String? district;
  final String city;
  final bool isDefault;

  Address({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    this.ward,
    this.district,
    required this.city,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = <String>[addressLine];
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    parts.add(city);
    return parts.join(', ');
  }

  Address copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? addressLine,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipient_name': recipientName,
    'phone': phone,
    'address_line': addressLine,
    'ward': ward,
    'district': district,
    'city': city,
    'is_default': isDefault,
  };

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['address_line'] ?? '',
      ward: json['ward'],
      district: json['district'],
      city: json['city'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }
}
