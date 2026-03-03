import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String id;
  final String ner;
  final String ovog;
  final String register;
  final String utas;
  final String albanTushaal;
  final String baiguullagaId;
  final String baiguullagaNer;
  final List<String> barilguud;

  AuthUser({
    required this.id,
    required this.ner,
    required this.ovog,
    required this.register,
    required this.utas,
    required this.albanTushaal,
    required this.baiguullagaId,
    required this.baiguullagaNer,
    required this.barilguud,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ner': ner,
    'ovog': ovog,
    'register': register,
    'utas': utas,
    'albanTushaal': albanTushaal,
    'baiguullagaId': baiguullagaId,
    'baiguullagaNer': baiguullagaNer,
    'barilguud': barilguud,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: (json['id'] ?? '').toString(),
    ner: (json['ner'] ?? '').toString(),
    ovog: (json['ovog'] ?? '').toString(),
    register: (json['register'] ?? '').toString(),
    utas: (json['utas'] ?? '').toString(),
    albanTushaal: (json['albanTushaal'] ?? '').toString(),
    baiguullagaId: (json['baiguullagaId'] ?? '').toString(),
    baiguullagaNer: (json['baiguullagaNer'] ?? '').toString(),
    barilguud: List<String>.from(json['barilguud'] ?? []),
  );
}

class AuthService {
  static const _baseUrl = 'http://103.143.40.175:8000';
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static String? _token;
  static AuthUser? _currentUser;

  /// The currently logged-in user
  static AuthUser? get currentUser => _currentUser;

  /// The auth token
  static String? get token => _token;

  /// Whether the user is logged in
  static bool get isLoggedIn => _token != null && _currentUser != null;

  /// Attempt to restore a previous session from local storage
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    final savedUser = prefs.getString(_userKey);

    if (savedToken != null && savedUser != null) {
      _token = savedToken;
      _currentUser = AuthUser.fromJson(json.decode(savedUser));
      return true;
    }
    return false;
  }

  /// Login with username and password
  static Future<AuthResult> login(String nevtrekhNer, String nuutsUg) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'nevtrekhNer': nevtrekhNer, 'nuutsUg': nuutsUg}),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final tokenVal = data['token'] as String;
        final result = data['result'] as Map<String, dynamic>;
        final baiguullaga = data['baiguullaga'] as Map<String, dynamic>?;

        final user = AuthUser(
          id: (result['_id'] ?? '').toString(),
          ner: (result['ner'] ?? '').toString(),
          ovog: (result['ovog'] ?? '').toString(),
          register: (result['register'] ?? '').toString(),
          utas: (result['utas'] ?? '').toString(),
          albanTushaal: (result['albanTushaal'] ?? '').toString(),
          baiguullagaId:
              (result['baiguullagiinId'] ?? baiguullaga?['_id'] ?? '')
                  .toString(),
          baiguullagaNer: (baiguullaga?['ner'] ?? '').toString(),
          barilguud: List<String>.from(result['barilguud'] ?? []),
        );

        // Save to state
        _token = tokenVal;
        _currentUser = user;

        // Persist locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, tokenVal);
        await prefs.setString(_userKey, json.encode(user.toJson()));

        return AuthResult.success(user);
      } else {
        // Server returned an error message. Translate if in English.
        String msg =
            data['message'] ??
            data['error'] ??
            'Нэвтрэх нэр эсвэл нууц үг буруу';

        final lowerMsg = msg.toLowerCase();
        if (lowerMsg.contains('unauthorized')) {
          msg = 'Хандах эрхгүй эсвэл эрх хүчингүй байна';
        } else if (lowerMsg.contains('forbidden')) {
          msg = 'Танд энэ үйлдлийг хийх зөвшөөрөл байхгүй байна';
        } else if (lowerMsg.contains('not found')) {
          msg = 'Мэдээлэл олдсонгүй';
        } else if (lowerMsg.contains('invalid credentials')) {
          msg = 'Нэвтрэх нэр эсвэл нууц үг буруу байна';
        } else if (lowerMsg.contains('bad request')) {
          msg = 'Хүсэлт буруу байна';
        } else if (lowerMsg.contains('internal server error')) {
          msg = 'Серверийн дотоод алдаа гарлаа';
        } else if (lowerMsg.contains('timeout')) {
          msg = 'Хүсэлтийн хугацаа дууслаа. Дахин оролдоно уу';
        } else if (lowerMsg.contains('connection')) {
          msg = 'Сервертэй холбогдож чадсангүй';
        }

        return AuthResult.failure(msg);
      }
    } on http.ClientException {
      return AuthResult.failure(
        'Сервертэй холбогдож чадсангүй. Интернэт холболтоо шалгана уу.',
      );
    } catch (e) {
      debugPrint('Login error: $e');
      if (e.toString().toLowerCase().contains('timeout')) {
        return AuthResult.failure('Холболт амжилтгүй. Хугацаа дууслаа.');
      }
      return AuthResult.failure(
        'Сервертэй холбогдож чадсангүй. Дахин оролдоно уу.',
      );
    }
  }

  /// Logout: clear all stored session data
  /// Note: FCM token deactivation is handled in root_screen.dart to avoid circular dependency
  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}

class AuthResult {
  final bool isSuccess;
  final AuthUser? user;
  final String? errorMessage;

  AuthResult._({required this.isSuccess, this.user, this.errorMessage});

  factory AuthResult.success(AuthUser user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
