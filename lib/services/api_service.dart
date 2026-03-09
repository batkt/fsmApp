import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Minimal, reusable HTTP client for the FSM API.
/// All endpoints go through here so headers/errors are handled once.
class ApiService {
  static const baseUrl = 'http://103.143.40.175:8000';
  static const _timeout = Duration(seconds: 20);

  // ── Helpers ──

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthService.token != null)
      'Authorization': 'Bearer ${AuthService.token}',
  };

  /// GET request → decoded JSON
  static Future<ApiResult> get(
    String path, {
    Map<String, String>? query,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return ApiResult.error(_friendlyError(e));
    }
  }

  /// POST request → decoded JSON
  static Future<ApiResult> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return ApiResult.error(_friendlyError(e));
    }
  }

  /// PUT request → decoded JSON
  static Future<ApiResult> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final res = await http
          .put(
            uri,
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return ApiResult.error(_friendlyError(e));
    }
  }

  /// PATCH request → decoded JSON
  static Future<ApiResult> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return ApiResult.error(_friendlyError(e));
    }
  }

  /// DELETE request
  static Future<ApiResult> delete(String path) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl$path'), headers: _headers)
          .timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return ApiResult.error(_friendlyError(e));
    }
  }

  // ── Internal ──

  static ApiResult _parse(http.Response res) {
    try {
      final data = json.decode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResult.ok(data);
      }
      final msg = data['message'] ?? data['error'] ?? 'Алдаа гарлаа';
      return ApiResult.error(msg.toString());
    } catch (_) {
      return ApiResult.error('Серверийн хариу буруу байна');
    }
  }

  static String _friendlyError(Object e) {
    debugPrint('API error: $e');
    final s = e.toString().toLowerCase();
    if (s.contains('timeout')) return 'Холболт удааширлаа. Дахин оролдоно уу.';
    if (s.contains('socket') || s.contains('connection')) {
      return 'Сервертэй холбогдож чадсангүй.';
    }
    return 'Алдаа гарлаа. Дахин оролдоно уу.';
  }
}

/// Light wrapper around API responses
class ApiResult {
  final bool success;
  final dynamic data;
  final String? message;

  ApiResult._({required this.success, this.data, this.message});

  factory ApiResult.ok(dynamic data) => ApiResult._(success: true, data: data);

  factory ApiResult.error(String msg) =>
      ApiResult._(success: false, message: msg);
}
