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
  final String role;

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
    required this.role,
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
    'role': role,
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
    role: (json['role'] ?? json['erkh'] ?? '').toString(),
  );
}

class AuthService {
  static const _baseUrl = 'http://103.236.194.26:8000';
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _bioTokenKey = 'auth_bio_token';
  static const _rememberMeKey = 'auth_remember_me';
  static const _savedUsernameKey = 'auth_saved_username';

  static String? _token;
  static AuthUser? _currentUser;
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// The currently logged-in user
  static AuthUser? get currentUser => _currentUser;

  /// The auth token
  static String? get token => _token;

  /// Whether the user is logged in
  static bool get isLoggedIn => _token != null && _currentUser != null;

  /// Attempt to restore a previous session from local storage
  /// Attempt to restore a previous session from local storage
  static Future<bool> restoreSession() async {
    final prefs = await _getPrefs();
    final savedToken = prefs.getString(_tokenKey);
    final savedUser = prefs.getString(_userKey);

    if (savedToken != null && savedUser != null) {
      _token = savedToken;
      _currentUser = AuthUser.fromJson(json.decode(savedUser));
      return true;
    }
    return false;
  }

  /// Get last saved user's phone number for login screen
  static Future<String?> getSavedUsername() async {
    final prefs = await _getPrefs();
    
    // First try the specific saved username key
    final saved = prefs.getString(_savedUsernameKey);
    if (saved != null) return saved;

    // Fallback to currently logged in user if exists
    final savedUser = prefs.getString(_userKey);
    if (savedUser != null) {
      final user = AuthUser.fromJson(json.decode(savedUser));
      return user.utas;
    }
    return null;
  }

  /// Save or clear the remembered username
  static Future<void> saveRememberedUsername(String? username, bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_rememberMeKey, enabled);
    if (enabled && username != null) {
      await prefs.setString(_savedUsernameKey, username);
    } else {
      await prefs.remove(_savedUsernameKey);
    }
  }

  /// Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_rememberMeKey) ?? true; // Default to true
  }

  /// Restores session using the persistent biometric token
  static Future<bool> restoreBiometricSession() async {
    final prefs = await _getPrefs();
    final savedToken = prefs.getString(_bioTokenKey);
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
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        debugPrint('Failed to parse login response: $e');
        return AuthResult.failure('Серверийн хариу буруу байна');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final tokenVal = data['token'] as String;
        final result = data['result'] as Map<String, dynamic>;
        // tureesBack might not return 'baiguullaga' object separately, so we handle it gracefully
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
          role: (result['erkh'] ?? '').toString(),
        );

        // Save to state
        _token = tokenVal;
        _currentUser = user;

        // Persist locally
        final prefs = await _getPrefs();
        await prefs.setString(_tokenKey, tokenVal);
        await prefs.setString(_userKey, json.encode(user.toJson()));
        await prefs.setString(_bioTokenKey, tokenVal); // Always update biometric token on successful login

        return AuthResult.success(user);
      } else {
        // Extract error message from various possible formats
        String msg = '';
        
        // Try different possible error message fields
        if (data['message'] != null) {
          msg = data['message'].toString();
        } else if (data['error'] != null) {
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
        
        // If still no message, use status code based defaults
        if (msg.isEmpty) {
          switch (response.statusCode) {
            case 401:
              msg = 'Нэвтрэх нэр эсвэл нууц код буруу байна';
              break;
            case 404:
              msg = 'Хэрэглэгч олдсонгүй';
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
              msg = 'Нэвтрэх нэр эсвэл нууц код буруу байна';
          }
        }

        // Translate common English error messages to Mongolian
        final lowerMsg = msg.toLowerCase();
        if (lowerMsg.contains('user not found') || 
            lowerMsg.contains('хэрэглэгч олдсонгүй') ||
            lowerMsg.contains('user does not exist')) {
          msg = 'Хэрэглэгч олдсонгүй';
        } else if (lowerMsg.contains('invalid password') || 
                   lowerMsg.contains('wrong password') ||
                   lowerMsg.contains('нууц код буруу') ||
                   lowerMsg.contains('unauthorized')) {
          msg = 'Нэвтрэх нэр эсвэл нууц код буруу байна';
        } else if (lowerMsg.contains('invalid credentials') ||
                   lowerMsg.contains('authentication failed')) {
          msg = 'Нэвтрэх нэр эсвэл нууц код буруу байна';
        } else if (lowerMsg.contains('forbidden')) {
          msg = 'Танд энэ үйлдлийг хийх зөвшөөрөл байхгүй байна';
        } else if (lowerMsg.contains('not found')) {
          msg = 'Мэдээлэл олдсонгүй';
        } else if (lowerMsg.contains('bad request')) {
          msg = 'Хүсэлт буруу байна';
        } else if (lowerMsg.contains('internal server error')) {
          msg = 'Серверийн дотоод алдаа гарлаа';
        } else if (lowerMsg.contains('timeout')) {
          msg = 'Хүсэлтийн хугацаа дууслаа. Дахин оролдоно уу';
        } else if (lowerMsg.contains('connection')) {
          msg = 'Сервертэй холбогдож чадсангүй';
        }

        debugPrint('Login failed: Status ${response.statusCode}, Message: $msg');
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
    final prefs = await _getPrefs();
    await prefs.remove(_tokenKey);
    // Note: We keep _userKey and _bioTokenKey so biometric login can work after logout
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
