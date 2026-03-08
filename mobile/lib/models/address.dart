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
