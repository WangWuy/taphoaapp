import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

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

  // ─── GET ────────────────────────────────────────────────
  Future<ApiResponse> get(String path, {Map<String, String>? queryParams}) async {
    try {
      final response = await http.get(
        _buildUri(path, queryParams),
        headers: _headers,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('GET $path error: $e');
      return ApiResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  // ─── POST ───────────────────────────────────────────────
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(
        _buildUri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('POST $path error: $e');
      return ApiResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  // ─── PUT ────────────────────────────────────────────────
  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        _buildUri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('PUT $path error: $e');
      return ApiResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  // ─── PATCH ──────────────────────────────────────────────
  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.patch(
        _buildUri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('PATCH $path error: $e');
      return ApiResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  // ─── DELETE ─────────────────────────────────────────────
  Future<ApiResponse> delete(String path) async {
    try {
      final response = await http.delete(
        _buildUri(path),
        headers: _headers,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('DELETE $path error: $e');
      return ApiResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  // ─── UPLOAD IMAGE ──────────────────────────────────────
  Future<ApiResponse> uploadImage(File imageFile) async {
    try {
      final uri = _buildUri('/upload');
      final request = http.MultipartRequest('POST', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      debugPrint('UPLOAD error: $e');
      return ApiResponse(success: false, message: 'Lỗi upload: $e');
    }
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
