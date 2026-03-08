import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Try auto-login from saved token
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    _api.setToken(token);
    final response = await _api.get(ApiConstants.me);

    if (response.success && response.data != null) {
      _currentUser = User.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      // Token expired or invalid
      _api.setToken(null);
      await prefs.remove('auth_token');
      return false;
    }
  }

  // Login
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.post(ApiConstants.login, body: {
      'phone': phone,
      'password': password,
    });

    _isLoading = false;

    if (response.success && response.data != null) {
      _currentUser = User.fromJson(response.data['user']);
      final token = response.data['token'] as String;
      _api.setToken(token);

      // Save token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'Đăng nhập thất bại';
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.post(ApiConstants.register, body: {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'password': password,
    });

    _isLoading = false;

    if (response.success && response.data != null) {
      _currentUser = User.fromJson(response.data['user']);
      final token = response.data['token'] as String;
      _api.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'Đăng ký thất bại';
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({String? name, String? email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;

    final response = await _api.patch('${ApiConstants.auth}/profile', body: body);

    _isLoading = false;
    if (response.success && response.data != null) {
      _currentUser = User.fromJson(response.data['user']);
      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'Cập nhật thất bại';
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({required String oldPassword, required String newPassword}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.patch('${ApiConstants.auth}/password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });

    _isLoading = false;
    if (response.success) {
      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'Đổi mật khẩu thất bại';
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
