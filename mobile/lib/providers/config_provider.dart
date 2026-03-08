import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class ConfigProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Map<String, dynamic>? _bankInfo;
  List<Map<String, dynamic>> _shippingRules = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  Map<String, dynamic>? get bankInfo => _bankInfo;
  List<Map<String, dynamic>> get shippingRules => _shippingRules;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  Future<void> loadConfig() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.config);
    if (response.success && response.data != null) {
      _bankInfo = response.data['bank'] as Map<String, dynamic>?;
      final shipping = response.data['shipping'] as Map<String, dynamic>? ?? {};
      _shippingRules = List<Map<String, dynamic>>.from(shipping['rules'] ?? []);
    } else {
      // Fallback defaults
      _shippingRules = [
        {'min_order': 0, 'max_order': 150000, 'fee': 10000},
        {'min_order': 150000, 'max_order': null, 'fee': 0},
      ];
    }

    _isLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  double calculateShippingFee(double orderTotal) {
    for (final rule in _shippingRules) {
      final minOrder = (rule['min_order'] ?? 0).toDouble();
      final maxOrder = rule['max_order'];
      final fee = (rule['fee'] ?? 0).toDouble();

      if (maxOrder == null) {
        if (orderTotal >= minOrder) return fee;
      } else {
        if (orderTotal >= minOrder && orderTotal < maxOrder.toDouble()) return fee;
      }
    }
    return 0;
  }

  double get freeShipThreshold {
    for (final rule in _shippingRules) {
      final fee = (rule['fee'] ?? 0).toDouble();
      if (fee == 0) {
        return (rule['min_order'] ?? 0).toDouble();
      }
    }
    return 150000; // fallback
  }
}
