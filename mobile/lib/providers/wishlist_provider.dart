import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class WishlistProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Product> _items = [];
  bool _isLoading = false;
  final Set<String> _wishlistProductIds = {};

  List<Product> get items => _items;
  bool get isLoading => _isLoading;
  int get count => _items.length;

  bool isInWishlist(String productId) => _wishlistProductIds.contains(productId);

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.get('/wishlist');
    if (response.success && response.data != null) {
      _items = (response.data as List)
          .map((e) => Product.fromJson(e['product']))
          .toList();
      _wishlistProductIds.clear();
      for (final item in _items) {
        _wishlistProductIds.add(item.id);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      return await removeFromWishlist(product.id);
    } else {
      return await addToWishlist(product);
    }
  }

  Future<bool> addToWishlist(Product product) async {
    // Optimistic update
    _items.insert(0, product);
    _wishlistProductIds.add(product.id);
    notifyListeners();

    final response = await _api.post('/wishlist', body: {
      'product_id': product.id,
    });

    if (!response.success) {
      // Rollback
      _items.removeWhere((p) => p.id == product.id);
      _wishlistProductIds.remove(product.id);
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> removeFromWishlist(String productId) async {
    // Keep reference for rollback
    final removedItem = _items.where((p) => p.id == productId).firstOrNull;
    final removedIndex = _items.indexWhere((p) => p.id == productId);

    // Optimistic update
    _items.removeWhere((p) => p.id == productId);
    _wishlistProductIds.remove(productId);
    notifyListeners();

    final response = await _api.delete('/wishlist/$productId');

    if (!response.success && removedItem != null) {
      // Rollback
      _items.insert(removedIndex.clamp(0, _items.length), removedItem);
      _wishlistProductIds.add(productId);
      notifyListeners();
      return false;
    }
    return true;
  }
}
