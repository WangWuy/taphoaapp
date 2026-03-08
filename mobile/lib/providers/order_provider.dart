import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Place order
  Future<Order?> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? note,
    String shippingType = 'standard',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.post(ApiConstants.orders, body: {
      'address_id': addressId,
      'payment_method': paymentMethod,
      'note': note,
      'shipping_type': shippingType,
    });

    _isLoading = false;

    if (response.success && response.data != null) {
      final order = Order.fromJson(response.data);
      notifyListeners();
      return order;
    } else {
      _error = response.message;
      notifyListeners();
      return null;
    }
  }

  // Load my orders
  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    notifyListeners();

    final Map<String, String> query = {};
    if (status != null) query['status'] = status;

    final response = await _api.get(ApiConstants.orders, queryParams: query);
    if (response.success && response.data != null) {
      _orders = (response.data as List)
          .map((e) => Order.fromJson(e))
          .toList();
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();

    final response = await _api.patch('${ApiConstants.orders}/$orderId/cancel');

    _isLoading = false;

    if (response.success) {
      await loadOrders(); // Reload list
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  // Confirm delivery (customer)
  Future<bool> confirmDelivery(String orderId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/confirm-delivery');

    if (response.success) {
      await loadOrders();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  // Confirm bank transfer payment (customer)
  Future<bool> confirmPayment(String orderId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/confirm-payment');

    if (response.success) {
      await loadOrders();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  // ─── Admin Methods ────────────────────────────────────
  List<Order> _adminOrders = [];
  List<Order> get adminOrders => _adminOrders;

  Future<void> loadAdminOrders({String? status, String? search, DateTime? dateFrom, DateTime? dateTo}) async {
    _isLoading = true;
    notifyListeners();

    final Map<String, String> query = {};
    if (status != null && status != 'all') query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (dateFrom != null) query['date_from'] = dateFrom.toIso8601String().split('T')[0];
    if (dateTo != null) query['date_to'] = dateTo.toIso8601String().split('T')[0];

    final response = await _api.get(ApiConstants.adminOrders, queryParams: query);
    if (response.success && response.data != null) {
      _adminOrders = (response.data as List)
          .map((e) => Order.fromJson(e))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final response = await _api.patch(
      '${ApiConstants.adminOrders}/$orderId/status',
      body: {'status': newStatus},
    );

    if (response.success) {
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  // ─── Admin Dashboard ──────────────────────────────────
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  Future<void> loadDashboard() async {
    final response = await _api.get('${ApiConstants.adminOrders}/stats/dashboard');
    if (response.success && response.data != null) {
      _dashboardStats = response.data as Map<String, dynamic>;
      notifyListeners();
    }
  }
}
