import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;

  int get totalItemsCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.cart);
    if (response.success && response.data != null) {
      _items = (response.data as List)
          .map((e) => CartItem.fromJson(e))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart(String productId, {int quantity = 1}) async {
    final response = await _api.post(ApiConstants.cart, body: {
      'product_id': productId,
      'quantity': quantity,
    });

    if (response.success) {
      await loadCart();
      return true;
    }
    return false;
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final response = await _api.put(
      '${ApiConstants.cart}/$cartItemId',
      body: {'quantity': quantity},
    );

    if (response.success) {
      await loadCart();
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    final response = await _api.delete('${ApiConstants.cart}/$cartItemId');
    if (response.success) {
      _items.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    await _api.delete(ApiConstants.cart);
    _items.clear();
    notifyListeners();
  }

  void clearLocal() {
    _items.clear();
    notifyListeners();
  }
}
