import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Minimal, reusable HTTP client for the FSM API.
/// All endpoints go through here so headers/errors are handled once.
class ApiService {
  static const baseUrl = 'http://103.236.194.26:8000';
  static const socketUrl = 'http://103.236.194.26:8000';
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

  /// MULTIPART request for file upload
  static Future<ApiResult> uploadFile(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));

      if (AuthService.token != null) {
        req.headers['Authorization'] = 'Bearer ${AuthService.token}';
      }

      if (fields != null) {
        req.fields.addAll(fields);
      }

      req.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      final streamRes = await req.send().timeout(const Duration(seconds: 45));
      final res = await http.Response.fromStream(streamRes);

      return _parse(res);
    } catch (e) {
      return ApiResult.error(_friendlyError(e));
    }
  }

  // ── Internal ──

  static ApiResult _parse(http.Response res) {
    try {
      // Handle empty response body
      if (res.body.isEmpty) {
        return ApiResult.error('Серверийн хариу хоосон байна');
      }

      // Check for common error patterns in raw body BEFORE parsing
      final body = res.body.toString();

      // Check for OTP errors in raw body (BEFORE JSON parsing)
      if (body.contains('Error: Буруу OTP код') ||
          body.contains('Буруу OTP код') ||
          body.contains('Error: Буруу OTP')) {
        return ApiResult.error('Буруу OTP код');
      }

      final data = json.decode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Even for 200 status, check if there's an error in the response
        if (data is Map) {
          // Backend now consistently returns { success: false, message: "..." }
          if (data['success'] == false) {
            final errorMsg = data['message']?.toString() ?? 'Алдаа гарлаа';
            return ApiResult.error(errorMsg);
          }

          // Legacy check: message field contains error keywords
          if (data['message'] != null) {
            final msg = data['message'].toString();
            if (msg.toLowerCase().contains('error') ||
                msg.contains('Буруу') ||
                msg.contains('буруу')) {
              return ApiResult.error(msg);
            }
          }
        }
        return ApiResult.ok(data);
      }

      // Extract error message - backend now consistently uses { success: false, message: "..." }
      String msg = '';
      if (data is Map) {
        // Priority 1: Check for consistent backend format
        if (data['success'] == false && data['message'] != null) {
          msg = data['message'].toString();
        }
        // Priority 2: Check message field directly
        else if (data['message'] != null) {
          msg = data['message'].toString();
        }
        // Priority 3: Fallback to other error fields (legacy support)
        else if (data['error'] != null) {
          msg = data['error'].toString();
        } else if (data['msg'] != null) {
          msg = data['msg'].toString();
        } else if (data['errors'] != null) {
          // Handle array of errors
          if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
            msg = (data['errors'] as List).first.toString();
          } else if (data['errors'] is Map) {
            final errors = data['errors'] as Map;
            msg = errors.values.first.toString();
          }
        }
      } else if (data is String) {
        // Sometimes error is just a string
        msg = data;
      }

      // If still no message, use status code based defaults
      if (msg.isEmpty) {
        switch (res.statusCode) {
          case 401:
            msg = 'Хандах эрхгүй байна';
            break;
          case 404:
            msg = 'Мэдээлэл олдсонгүй';
            break;
          case 400:
            msg = 'Хүсэлт буруу байна';
            break;
          case 403:
            msg = 'Хандах эрхгүй байна';
            break;
          case 500:
            msg = 'Серверийн дотоод алдаа гарлаа';
            break;
          default:
            msg = 'Алдаа гарлаа';
        }
      }

      return ApiResult.error(msg);
    } catch (e) {
      // Log the actual error for debugging
      debugPrint(
        'API parse error: $e, status: ${res.statusCode}, body: ${res.body}',
      );
      // Try to extract error from raw body if JSON parsing fails
      final body = res.body.toString();
      final lowerBody = body.toLowerCase();

      // Check if response is HTML (server error page)
      final isHtml =
          body.trim().startsWith('<!DOCTYPE') ||
          body.trim().startsWith('<html') ||
          lowerBody.contains('<html') ||
          lowerBody.contains('<!doctype');

      // PRIORITY 1: Check for OTP errors (most common)
      if (body.contains('Error: Буруу OTP код') ||
          body.contains('Буруу OTP код') ||
          body.contains('Error: Буруу OTP') ||
          lowerBody.contains('буруу otp код')) {
        return ApiResult.error('Буруу OTP код');
      }

      // PRIORITY 2: Check for phone number/employee not found errors
      if (lowerBody.contains('no employee found') ||
          lowerBody.contains('employee not found') ||
          lowerBody.contains('дугаар олдсонгүй') ||
          lowerBody.contains('бүртгэлгүй') ||
          body.contains('❌ No employee found')) {
        return ApiResult.error('Утасны дугаар олдсонгүй');
      }

      // PRIORITY 3: Try to extract error message after "Error:"
      if (body.contains('Error:')) {
        // Try multiple patterns
        var match = RegExp(r'Error:\s*([^\n\r<]+)').firstMatch(body);
        if (match == null) {
          match = RegExp(r'Error[:\s]+([^\n\r<]+)').firstMatch(body);
        }
        if (match != null) {
          final errorText = match.group(1)?.trim() ?? '';
          if (errorText.isNotEmpty && !errorText.contains('<')) {
            return ApiResult.error(errorText);
          }
        }
      }

      // PRIORITY 4: Handle HTML error pages
      if (isHtml) {
        // Try to extract error from HTML <pre> tags or <title>
        var htmlMatch = RegExp(
          r'<pre[^>]*>([^<]+)</pre>',
          caseSensitive: false,
        ).firstMatch(body);
        if (htmlMatch == null) {
          htmlMatch = RegExp(
            r'<title[^>]*>([^<]+)</title>',
            caseSensitive: false,
          ).firstMatch(body);
        }
        if (htmlMatch != null) {
          final htmlError = htmlMatch.group(1)?.trim() ?? '';
          if (htmlError.isNotEmpty) {
            // Translate common HTML error messages
            if (htmlError.toLowerCase().contains('internal server error') ||
                htmlError.toLowerCase().contains('500')) {
              return ApiResult.error('Серверийн дотоод алдаа гарлаа');
            }
            return ApiResult.error(htmlError);
          }
        }

        // For HTML responses with 500 status, return server error message
        if (res.statusCode == 500) {
          return ApiResult.error('Серверийн дотоод алдаа гарлаа');
        }
      }

      // If we still don't have an error, use status code based message
      switch (res.statusCode) {
        case 500:
          return ApiResult.error('Серверийн дотоод алдаа гарлаа');
        case 400:
          return ApiResult.error('Хүсэлт буруу байна');
        case 401:
          return ApiResult.error('Хандах эрхгүй байна');
        case 403:
          return ApiResult.error('Хандах эрхгүй байна');
        case 404:
          return ApiResult.error('Мэдээлэл олдсонгүй');
        default:
          return ApiResult.error('Серверийн хариу буруу байна');
      }
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
