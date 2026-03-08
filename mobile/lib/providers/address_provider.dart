import 'package:flutter/material.dart';
import '../models/address.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class AddressProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Address? get defaultAddress =>
      _addresses.where((a) => a.isDefault).firstOrNull;

  Future<void> loadAddresses() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.addresses);
    if (response.success && response.data != null) {
      _addresses = (response.data as List)
          .map((e) => Address.fromJson(e))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAddress({
    required String recipientName,
    required String phone,
    required String addressLine,
    String? ward,
    String? district,
    required String city,
    bool isDefault = false,
  }) async {
    final response = await _api.post(ApiConstants.addresses, body: {
      'recipient_name': recipientName,
      'phone': phone,
      'address_line': addressLine,
      'ward': ward,
      'district': district,
      'city': city,
      'is_default': isDefault,
    });

    if (response.success) {
      await loadAddresses();
      return true;
    }
    _error = response.message;
    return false;
  }

  Future<bool> updateAddress(String id, {
    String? recipientName,
    String? phone,
    String? addressLine,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (recipientName != null) body['recipient_name'] = recipientName;
    if (phone != null) body['phone'] = phone;
    if (addressLine != null) body['address_line'] = addressLine;
    if (ward != null) body['ward'] = ward;
    if (district != null) body['district'] = district;
    if (city != null) body['city'] = city;
    if (isDefault != null) body['is_default'] = isDefault;

    final response = await _api.put('${ApiConstants.addresses}/$id', body: body);

    if (response.success) {
      await loadAddresses();
      return true;
    }
    _error = response.message;
    return false;
  }

  Future<bool> deleteAddress(String id) async {
    final response = await _api.delete('${ApiConstants.addresses}/$id');
    if (response.success) {
      await loadAddresses();
      return true;
    }
    return false;
  }

  Future<bool> setDefault(String id) async {
    final response = await _api.patch('${ApiConstants.addresses}/$id/default');
    if (response.success) {
      await loadAddresses();
      return true;
    }
    return false;
  }
}
