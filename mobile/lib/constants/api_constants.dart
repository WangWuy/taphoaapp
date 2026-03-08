import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ─── Base URL ────────────────────────────────────────────
  // Đọc từ file .env, fallback về localhost nếu không có
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3001/api';

  // ─── Auth ────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // ─── Products & Categories ───────────────────────────────
  static const String products = '/products';
  static const String categories = '/categories';

  // ─── Cart ────────────────────────────────────────────────
  static const String cart = '/cart';

  // ─── Addresses ───────────────────────────────────────────
  static const String addresses = '/addresses';

  // ─── Orders ──────────────────────────────────────────────
  static const String orders = '/orders';

  // ─── Config ──────────────────────────────────────────────
  static const String config = '/config';

  // ─── Notifications ─────────────────────────────────────
  static const String notifications = '/notifications';

  // ─── Admin ───────────────────────────────────────────────
  static const String adminOrders = '/admin/orders';
  static const String adminProducts = '/admin/products';
  static const String adminCustomers = '/admin/customers';
  static const String adminCategories = '/admin/categories';

  // ─── Auth ────────────────────────────────────────────────
  static const String auth = '/auth';

  // ─── Image URL Helper ───────────────────────────────────
  /// Converts a relative image path (e.g. `/uploads/file.jpg`) to a full URL
  /// using the current API base URL. If the URL is already absolute, returns as-is.
  static String? getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    // Already a full URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // Build from base URL: remove `/api` suffix to get server root
    final base = baseUrl;
    final serverRoot = base.endsWith('/api')
        ? base.substring(0, base.length - 4)
        : base;
    return '$serverRoot$imageUrl';
  }
}
