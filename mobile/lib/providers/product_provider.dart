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
  bool _isLoadingMore = false;
  String? _error;
  int? _selectedCategoryId;
  String? _searchQuery;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 20;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentPage < _totalPages;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;

  String get selectedCategoryName {
    if (_selectedCategoryId == null) return 'Tất cả';
    return _categories
        .firstWhere((c) => c.id == _selectedCategoryId,
            orElse: () => Category(id: 0, name: 'Tất cả', slug: ''))
        .name;
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh || _products.isEmpty) {
      _currentPage = 1;
      _isLoading = true;
      notifyListeners();
    }

    // Load categories (only on first load or refresh)
    if (_categories.isEmpty || refresh) {
      final catResponse = await _api.get(ApiConstants.categories);
      if (catResponse.success && catResponse.data != null) {
        _categories = (catResponse.data as List)
            .map((e) => Category.fromJson(e))
            .toList();
      }
    }

    // Build query params
    final Map<String, String> query = {
      'page': '$_currentPage',
      'limit': '$_pageSize',
    };
    if (_selectedCategoryId != null) {
      query['category_id'] = _selectedCategoryId.toString();
    }
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      query['search'] = _searchQuery!;
    }

    final prodResponse = await _api.get(ApiConstants.products, queryParams: query);
    if (prodResponse.success && prodResponse.data != null) {
      final newProducts = (prodResponse.data as List)
          .map((e) => Product.fromJson(e))
          .toList();

      // Parse pagination from response
      final pagination = prodResponse.pagination;
      if (pagination != null) {
        _totalPages = pagination['totalPages'] ?? 1;
        _currentPage = pagination['page'] ?? 1;
      }

      if (_currentPage == 1) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }
    } else {
      _error = prodResponse.message;
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    await loadProducts();
  }

  Future<void> filterByCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    _searchQuery = null;
    _currentPage = 1;
    await loadProducts(refresh: true);
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    _selectedCategoryId = null;
    _currentPage = 1;
    await loadProducts(refresh: true);
  }
}
