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
  /// zevtabs/turees-ээс олгосон цонхны эрх (FSM модулийн табуудыг шийднэ)
  final List<String> tsonkhniiErkhuud;
  /// Нэвтэрсэн систем: 'fsm' (turees/FSM) эсвэл 'irts' (irts.zevtabs.mn)
  final String system;
  /// zevtabs-д байгууллагад сонгосон цонхнууд (Цонхны эрх). null = мэдэгдэхгүй
  final List<String>? moduluud;

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
    this.tsonkhniiErkhuud = const [],
    this.system = 'fsm',
    this.moduluud,
  });

  bool get irtsEsekh => system == 'irts';

  bool erkhtei(String zam) => tsonkhniiErkhuud.contains(zam);

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
    'tsonkhniiErkhuud': tsonkhniiErkhuud,
    'system': system,
    'moduluud': moduluud,
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
    tsonkhniiErkhuud: List<String>.from(
      (json['tsonkhniiErkhuud'] as List? ?? []).map((e) => e.toString()),
    ),
    system: (json['system'] ?? 'fsm').toString(),
    moduluud: (json['moduluud'] as List?)?.map((e) => e.toString()).toList(),
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

  // ── Холбосон irts бүртгэл ──
  // FSM-ээр нэвтэрсэн хүн irts.zevtabs.mn-д ч бүртгэлтэй бол (нэг нэр/нууц
  // үгээр, эсвэл профайлаас холбосон) Ирц/Цалин-г тэр бүртгэлээр ажиллуулна —
  // ингэснээр ирцийн жинхэнэ түүх (irtsBack) харагдана.
  // TODO: утасны дугаараар бүртгэл нэгтгэсний дараа сервер нэг нэвтрэлтээр хоёуланг нь буцаана.
  static const _irtsTokenKey = 'auth_irts_token';
  static const _irtsUserKey = 'auth_irts_user';
  static String? _irtsToken;
  static AuthUser? _irtsUser;

  /// Ирц/Цалин-д ашиглах irts бүртгэл: irts-ээр нэвтэрсэн бол үндсэн хэрэглэгч,
  /// FSM-ээр нэвтэрсэн бол холбосон irts бүртгэл (байхгүй бол null).
  static AuthUser? get irtsUser => (_currentUser?.irtsEsekh ?? false) ? _currentUser : _irtsUser;
  static String? get irtsToken => (_currentUser?.irtsEsekh ?? false) ? _token : _irtsToken;

  /// FSM болон irts хоёр бүртгэлтэй (холбогдсон) эсэх
  static bool get khoyorBurtgeltei => _currentUser != null && !_currentUser!.irtsEsekh && _irtsUser != null;

  /// Холбосон бүртгэл өөрчлөгдөхөд табуудыг дахин зурахад
  static final burtgelOorchlogdson = ValueNotifier<int>(0);

  static Future<void> _irtsKhadgalakh(String? token, AuthUser? user) async {
    final oorchlogdson = _irtsUser?.id != user?.id;
    _irtsToken = token;
    _irtsUser = user;
    if (oorchlogdson) burtgelOorchlogdson.value++;
    final prefs = await _getPrefs();
    if (token == null || user == null) {
      await prefs.remove(_irtsTokenKey);
      await prefs.remove(_irtsUserKey);
    } else {
      await prefs.setString(_irtsTokenKey, token);
      await prefs.setString(_irtsUserKey, json.encode(user.toJson()));
    }
  }

  static Future<void> _irtsSergeekh() async {
    final prefs = await _getPrefs();
    final t = prefs.getString(_irtsTokenKey);
    final u = prefs.getString(_irtsUserKey);
    if (t != null && u != null) {
      _irtsToken = t;
      _irtsUser = AuthUser.fromJson(json.decode(u));
    }
  }

  /// Профайлаас: өөр нэр/нууц үгтэй irts бүртгэлээ FSM бүртгэлдээ холбох
  static Future<AuthResult> irtsHolbokh(String nevtrekhNer, String nuutsUg) async {
    if (_currentUser == null || _currentUser!.irtsEsekh) {
      return AuthResult.failure('FSM бүртгэлээр нэвтэрсэн байх шаардлагатай');
    }
    final r = await _irtsNevtrey(nevtrekhNer, nuutsUg);
    if (!r.isSuccess) return r;
    await _irtsKhadgalakh(r.token, r.user);
    await _moduluudAvakh(irts: true);
    return r;
  }

  /// Холбосон irts бүртгэлийг салгах
  static Future<void> irtsSalgakh() => _irtsKhadgalakh(null, null);

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
      await _irtsSergeekh();
      return true;
    }
    return false;
  }

  /// tureesBack (TureesTest) — FSM байгууллагын zevtabs модулиудыг эндээс авна
  static const _tureesUrl = 'http://103.236.194.26:8081';

  /// zevtabs-ийн "Цонхны эрх"-д байгууллагад сонгосон цонхнуудыг татаж хадгална.
  /// Алдаа гарвал өмнөх утга хэвээр (null бол апп ажилтны эрхээр л шийднэ).
  static Future<void> moduluudShinechlekh() async {
    await Future.wait([
      _moduluudAvakh(irts: false),
      if (_irtsUser != null && !(_currentUser?.irtsEsekh ?? true)) _moduluudAvakh(irts: true),
    ]);
  }

  /// [irts] true бол холбосон irts бүртгэлийн, үгүй бол үндсэн хэрэглэгчийн модулиуд
  static Future<void> _moduluudAvakh({required bool irts}) async {
    final user = irts ? _irtsUser : _currentUser;
    final token = irts ? _irtsToken : _token;
    if (token == null || user == null) return;
    try {
      final url = user.irtsEsekh ? '$irtsUrl/erkhiinMedeelelAvya' : '$_tureesUrl/erkhiinMedeelelAvya';
      final res = await http
          .post(Uri.parse(url), headers: {'Content-Type': 'application/json', 'Authorization': 'bearer $token'}, body: '{}')
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final data = json.decode(res.body);
      final list = data is Map ? data['moduluud'] : null;
      if (list is! List) return;
      final zamuud = [for (final m in list) if (m is Map && m['zam'] != null) m['zam'].toString()];
      final shine = AuthUser.fromJson({...user.toJson(), 'moduluud': zamuud});
      if (irts) {
        await _irtsKhadgalakh(token, shine);
      } else {
        _currentUser = shine;
        final prefs = await _getPrefs();
        await prefs.setString(_userKey, json.encode(shine.toJson()));
      }
    } catch (e) {
      debugPrint('[Auth] модуль шинэчилж чадсангүй: $e');
    }
  }

  /// Цонхны эрхийг серверээс дахин уншина (/me). Алдаа гарвал хадгалсан эрх хэвээр.
  static Future<AuthUser?> erkhShinechlekh() async {
    final user = _currentUser;
    if (_token == null || user == null || user.irtsEsekh) return user;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return user;
      final ajiltan = (json.decode(res.body) as Map)['ajiltan'] as Map?;
      if (ajiltan == null) return user;
      final shine = AuthUser.fromJson({
        ...user.toJson(),
        'barilguud': ajiltan['barilguud'] ?? user.barilguud,
        'role': ajiltan['erkh'] ?? user.role,
        'tsonkhniiErkhuud': ajiltan['tsonkhniiErkhuud'] ?? const [],
      });
      _currentUser = shine;
      final prefs = await _getPrefs();
      await prefs.setString(_userKey, json.encode(shine.toJson()));
      return shine;
    } catch (e) {
      debugPrint('[Auth] эрх шинэчилж чадсангүй: $e');
      return user;
    }
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
      await _irtsSergeekh();
      return true;
    }
    return false;
  }

  /// irts.zevtabs.mn-ийн API (irts-ийн бүртгэлтэй ажилтан)
  static const irtsUrl = 'https://irts.zevtabs.mn/api';

  /// Нэвтрэх: FSM (fsmBack/turees) болон irts (irtsBack) бүртгэлийг зэрэг шалгана.
  ///  • зөвхөн FSM → FSM хэрэглэгч (Ирц нь FSM горимын irtsBack-ээр)
  ///  • зөвхөн irts → irts хэрэглэгч (Ирц, Хүсэлт, Цалин)
  ///  • хоёулаа → FSM үндсэн, irts бүртгэлийг холбож Ирц/Цалин-д ашиглана
  /// TODO: FSM, irts хэрэглэгчдийг утасны дугаараар нэгтгэсний дараа нэг л бүртгэлтэй болно.
  static Future<AuthResult> login(String nevtrekhNer, String nuutsUg) async {
    final res = await Future.wait([
      _fsmNevtrey(nevtrekhNer, nuutsUg),
      _irtsNevtrey(nevtrekhNer, nuutsUg),
    ]);
    final fsm = res[0], irts = res[1];
    if (fsm.isSuccess) {
      await _sessionKhadgalakh(fsm);
      // Ижил нэр/нууц үгтэй irts бүртгэл байвал холбоно; үгүй бол өмнө нь
      // профайлаас холбосон бүртгэл (ижил хүнийх бол) хэвээр үлдэнэ.
      if (irts.isSuccess) {
        await _irtsKhadgalakh(irts.token, irts.user);
      } else {
        await _irtsSergeekh();
        if (_irtsUser != null && !_ijilKhun(fsm.user!, _irtsUser!)) await _irtsKhadgalakh(null, null);
      }
      return fsm;
    }
    if (irts.isSuccess) {
      await _sessionKhadgalakh(irts);
      await _irtsKhadgalakh(null, null);
      return irts;
    }
    // Хоёулаа татгалзвал энгийн мессеж; сүлжээний алдааг тэр чигээр нь харуулна
    return irts.errorMessage == _buruuMsg ? AuthResult.failure(_buruuMsg) : fsm;
  }

  /// Холбосон irts бүртгэл тухайн FSM хэрэглэгчийнх мөн эсэх (утас эсвэл регистрээр)
  static bool _ijilKhun(AuthUser a, AuthUser b) {
    String c(String s) => s.replaceAll(RegExp(r'\D'), '');
    if (c(a.utas).isNotEmpty && c(a.utas) == c(b.utas)) return true;
    return a.register.isNotEmpty && a.register.toUpperCase() == b.register.toUpperCase();
  }

  static Future<void> _sessionKhadgalakh(AuthResult r) async {
    _token = r.token;
    _currentUser = r.user;
    final prefs = await _getPrefs();
    await prefs.setString(_tokenKey, r.token!);
    await prefs.setString(_userKey, json.encode(r.user!.toJson()));
    await prefs.setString(_bioTokenKey, r.token!);
  }

  static const _buruuMsg = 'Нэвтрэх нэр эсвэл нууц код буруу байна';

  static Future<AuthResult> _irtsNevtrey(String nevtrekhNer, String nuutsUg) async {
    try {
      final res = await http
          .post(
            Uri.parse('$irtsUrl/ajiltanNevtrey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'nevtrekhNer': nevtrekhNer, 'nuutsUg': nuutsUg}),
          )
          .timeout(const Duration(seconds: 15));
      Map<String, dynamic>? data;
      try {
        data = json.decode(res.body) as Map<String, dynamic>;
      } catch (_) {}
      if (res.statusCode == 200 && data?['token'] != null && data?['result'] is Map) {
        final r = data!['result'] as Map<String, dynamic>;
        final user = AuthUser(
          id: (r['_id'] ?? '').toString(),
          ner: (r['ner'] ?? '').toString(),
          ovog: (r['ovog'] ?? '').toString(),
          register: (r['register'] ?? '').toString(),
          utas: (r['utas'] ?? '').toString(),
          albanTushaal: (r['albanTushaal'] ?? '').toString(),
          baiguullagaId: (r['baiguullagiinId'] ?? '').toString(),
          baiguullagaNer: (r['baiguullagiinNer'] ?? r['zogsoolNer'] ?? '').toString(),
          barilguud: List<String>.from((r['barilguud'] as List? ?? []).map((e) => e.toString())),
          role: (r['erkh'] ?? '').toString(),
          tsonkhniiErkhuud: List<String>.from((r['tsonkhniiErkhuud'] as List? ?? []).map((e) => e.toString())),
          system: 'irts',
        );
        return AuthResult.success(user, token: data['token'] as String);
      }
      final aldaa = data?['aldaa']?.toString() ?? '';
      // Буруу нэр/нууц үг бол нэг ижил мессеж; лицензийн гэх мэт бусад алдааг тэр чигээр
      if (aldaa.isEmpty || aldaa.contains('буруу')) return AuthResult.failure(_buruuMsg);
      return AuthResult.failure(aldaa);
    } catch (e) {
      debugPrint('[Auth] irts нэвтрэлт: $e');
      return AuthResult.failure('Сервертэй холбогдож чадсангүй');
    }
  }

  /// FSM (turees) бүртгэлээр нэвтрэх
  static Future<AuthResult> _fsmNevtrey(String nevtrekhNer, String nuutsUg) async {
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
          tsonkhniiErkhuud: List<String>.from(
            (result['tsonkhniiErkhuud'] as List? ?? []).map((e) => e.toString()),
          ),
        );

        // Төлөвт хадгалахыг login() шийднэ (irts бүртгэлтэй зэрэг шалгадаг тул)
        return AuthResult.success(user, token: tokenVal);
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
    // Холбосон irts бүртгэлийг санах ойд л цэвэрлэнэ (biometric нэвтрэлт сэргээнэ)
    _irtsToken = null;
    _irtsUser = null;
    // Note: We keep _userKey and _bioTokenKey so biometric login can work after logout
  }
}

class AuthResult {
  final bool isSuccess;
  final AuthUser? user;
  final String? errorMessage;
  final String? token;

  AuthResult._({required this.isSuccess, this.user, this.errorMessage, this.token});

  factory AuthResult.success(AuthUser user, {String? token}) =>
      AuthResult._(isSuccess: true, user: user, token: token);

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}
