import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String? _refreshToken;
  bool _isRefreshing = false;

  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 2;

  void setToken(String? token) => _token = token;
  void setRefreshToken(String? token) => _refreshToken = token;

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final baseUri = Uri.parse(ApiConstants.baseUrl);
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: '${baseUri.path}$path',
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }

  // ─── Token Refresh ────────────────────────────────────
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing || _refreshToken == null) return false;
    _isRefreshing = true;

    try {
      final response = await http.post(
        _buildUri('/auth/refresh'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(_timeout);

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['status'] == 'success') {
        final newToken = body['data']['token'] as String;
        _token = newToken;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', newToken);

        debugPrint('🔄 Token refreshed successfully');
        _isRefreshing = false;
        return true;
      }
    } catch (e) {
      debugPrint('🔄 Token refresh failed: $e');
    }

    _isRefreshing = false;
    return false;
  }

  // ─── GET ────────────────────────────────────────────────
  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    return _requestWithRetry(() => http.get(
      _buildUri(path, queryParams),
      headers: _headers,
    ).timeout(_timeout), 'GET', path);
  }

  // ─── POST ───────────────────────────────────────────────
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    return _requestWithRetry(() => http.post(
      _buildUri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout), 'POST', path);
  }

  // ─── PUT ────────────────────────────────────────────────
  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    return _requestWithRetry(() => http.put(
      _buildUri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout), 'PUT', path);
  }

  // ─── PATCH ──────────────────────────────────────────────
  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    return _requestWithRetry(() => http.patch(
      _buildUri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout), 'PATCH', path);
  }

  // ─── DELETE ─────────────────────────────────────────────
  Future<ApiResponse> delete(String path) async {
    return _requestWithRetry(() => http.delete(
      _buildUri(path),
      headers: _headers,
    ).timeout(_timeout), 'DELETE', path);
  }

  // ─── UPLOAD IMAGE ──────────────────────────────────────
  static const Duration _uploadTimeout = Duration(seconds: 60);

  /// Warm up server if it's in cold start (Render free tier)
  Future<void> _warmUpServer() async {
    try {
      final uri = _buildUri('/health');
      debugPrint('🔥 Warming up server...');
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      debugPrint('🔥 Server warm: ${response.statusCode}');
    } catch (e) {
      debugPrint('🔥 Warm-up ping failed (may still work): $e');
    }
  }

  Future<ApiResponse> uploadImage(File imageFile) async {
    for (int attempt = 0; attempt <= 2; attempt++) {
      try {
        final uri = _buildUri('/upload');
        debugPrint('📤 UPLOAD attempt ${attempt + 1}: $uri');
        debugPrint('📤 File: ${imageFile.path} (${await imageFile.length()} bytes)');

        final request = http.MultipartRequest('POST', uri);
        if (_token != null) {
          request.headers['Authorization'] = 'Bearer $_token';
        }

        // Explicitly set content-type from extension (fromPath may default to octet-stream)
        final ext = p.extension(imageFile.path).toLowerCase();
        final mimeMap = {'.jpg': 'jpeg', '.jpeg': 'jpeg', '.png': 'png', '.gif': 'gif', '.webp': 'webp'};
        final subtype = mimeMap[ext] ?? 'jpeg';
        debugPrint('📤 File ext: $ext → image/$subtype');

        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', subtype),
        ));

        final streamedResponse = await request.send().timeout(_uploadTimeout);
        final response = await http.Response.fromStream(streamedResponse);
        debugPrint('📤 UPLOAD response: ${response.statusCode} ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

        // 502 = Render cold start, warm up and retry
        if (response.statusCode == 502 && attempt < 2) {
          debugPrint('📤 Got 502 (server cold start), warming up and retrying...');
          await _warmUpServer();
          continue;
        }

        // Auto-refresh on 401 (first attempt only)
        if (response.statusCode == 401 && attempt == 0 && _refreshToken != null) {
          debugPrint('📤 UPLOAD got 401, trying token refresh...');
          final refreshed = await _tryRefreshToken();
          if (refreshed) continue;
        }

        return _processResponse(response);
      } catch (e) {
        debugPrint('📤 UPLOAD error (attempt ${attempt + 1}): $e');
        if (attempt == 2) {
          return ApiResponse(success: false, message: _friendlyError(e));
        }
        // First failure might be cold start, warm up
        if (attempt == 0) await _warmUpServer();
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return ApiResponse(success: false, message: 'Upload thất bại sau nhiều lần thử');
  }

  // ─── Request with auto-retry on 401 ───────────────────
  Future<ApiResponse> _requestWithRetry(
    Future<http.Response> Function() request,
    String method,
    String path,
  ) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await request();
        final result = _processResponse(response);

        // Auto-refresh on 401 (first attempt only)
        if (response.statusCode == 401 && attempt == 0 && _refreshToken != null) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) continue; // Retry with new token
        }

        return result;
      } catch (e) {
        debugPrint('$method $path error (attempt ${attempt + 1}): $e');
        if (attempt == _maxRetries) {
          return ApiResponse(success: false, message: _friendlyError(e));
        }
        // Brief pause before retry
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    return ApiResponse(success: false, message: 'Lỗi không xác định');
  }

  // ─── Process Response ───────────────────────────────────
  ApiResponse _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final status = body['status'];
      final message = body['message'];
      final data = body['data'];
      final pagination = body['pagination'];

      if (response.statusCode >= 200 && response.statusCode < 300 && status == 'success') {
        return ApiResponse(success: true, data: data, pagination: pagination);
      } else {
        return ApiResponse(
          success: false,
          message: message ?? 'Đã xảy ra lỗi',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Lỗi xử lý response',
        statusCode: response.statusCode,
      );
    }
  }

  // ─── Friendly Error Messages ───────────────────────────
  String _friendlyError(dynamic error) {
    if (error is SocketException) {
      return 'Không thể kết nối server. Kiểm tra kết nối mạng.';
    }
    if (error.toString().contains('TimeoutException')) {
      return 'Server phản hồi quá chậm. Vui lòng thử lại.';
    }
    if (error.toString().contains('HandshakeException')) {
      return 'Lỗi bảo mật kết nối. Vui lòng thử lại.';
    }
    return 'Lỗi kết nối: ${error.toString().length > 80 ? error.toString().substring(0, 80) : error}';
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? pagination;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.pagination,
  });
}
