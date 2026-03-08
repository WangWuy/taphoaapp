import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;

  String get selectedCategoryName {
    if (_selectedCategoryId == null) return 'Tất cả';
    return _categories
        .firstWhere((c) => c.id == _selectedCategoryId,
            orElse: () => Category(id: 0, name: 'Tất cả', slug: ''))
        .name;
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    // Load categories
    final catResponse = await _api.get(ApiConstants.categories);
    if (catResponse.success && catResponse.data != null) {
      _categories = (catResponse.data as List)
          .map((e) => Category.fromJson(e))
          .toList();
    }

    // Load products
    final Map<String, String> query = {};
    if (_selectedCategoryId != null) {
      query['category_id'] = _selectedCategoryId.toString();
    }

    final prodResponse = await _api.get(ApiConstants.products, queryParams: query);
    if (prodResponse.success && prodResponse.data != null) {
      _products = (prodResponse.data as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } else {
      _error = prodResponse.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> filterByCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    await loadProducts();
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _selectedCategoryId = null;
      await loadProducts();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final response = await _api.get(ApiConstants.products, queryParams: {
      'search': query,
    });

    if (response.success && response.data != null) {
      _products = (response.data as List)
          .map((e) => Product.fromJson(e))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }
}
