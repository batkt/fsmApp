import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'project_service.dart';

/// irtsBack-ийн FSM горимын instance (TOKHIRGOO=fsm). FSM-ийн нэвтрэлтийн
/// токен (turees-ийн APP_SECRET) шууд хүчинтэй.
class IrtsService {
  /// FSM хэрэглэгч: irtsBack-ийн FSM горимын instance; irts хэрэглэгч: irts.zevtabs.mn
  static const fsmUrl = 'http://103.236.194.26:8087';
  /// irts бүртгэл (үндсэн эсвэл холбосон) байвал irts.zevtabs.mn, үгүй бол FSM горим
  static bool get _irtsBurtgel => AuthService.irtsUser != null;
  static String get baseUrl => _irtsBurtgel ? AuthService.irtsUrl : fsmUrl;
  static String? get _token => _irtsBurtgel ? AuthService.irtsToken : AuthService.token;
  /// Ирцэд ашиглах ажилтан (FSM+irts хэрэглэгчид irts бүртгэлийнх)
  static AuthUser? get ajiltan => AuthService.irtsUser ?? AuthService.currentUser;
  static const _timeout = Duration(seconds: 25);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'bearer $_token',
      };

  static String? get baiguullagiinId => ajiltan?.baiguullagaId;

  /// Идэвхтэй төслийн барилга, эсвэл ажилтны эхний барилга
  static String? get barilgiinId {
    // FSM-ийн төслийн барилга irts байгууллагад хамаарахгүй тул irts бүртгэлтэй бол ашиглахгүй
    final p = ProjectService.activeProject.value;
    if (!_irtsBurtgel && p != null && p.barilgiinId.isNotEmpty) return p.barilgiinId;
    final b = ajiltan?.barilguud ?? const [];
    if (b.isNotEmpty) return b.first;
    // Admin зэрэг барилга оноогоогүй хэрэглэгч: байгууллагын эхний барилга
    // (irts.zevtabs.mn-тэй ижил). barilgaAvya() дуудсаны дараа тодорхой болно.
    return _baiguullagiinBarilga;
  }

  static String? _baiguullagiinBarilga;

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('$baseUrl$path'),
            headers: _headers,
            body: json.encode({
              'baiguullagiinId': baiguullagiinId,
              'barilgiinId': barilgiinId,
              ...body,
            }))
        .timeout(_timeout);
    return _parse(res);
  }

  static Future<dynamic> _get(String path, [Map<String, dynamic>? params]) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: params?.map(
        (k, v) => MapEntry(k, v is String ? v : json.encode(v)),
      ),
    );
    final res = await http.get(uri, headers: _headers).timeout(_timeout);
    return _parse(res);
  }

  static dynamic _parse(http.Response res) {
    dynamic data;
    try {
      data = json.decode(res.body);
    } catch (_) {
      data = res.body; // "Amjilttai" гэх мэт энгийн текст
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final msg = data is Map
        ? (data['aldaa'] ?? data['message'] ?? 'Алдаа гарлаа').toString()
        : 'Сервертэй холбогдож чадсангүй (${res.statusCode})';
    throw IrtsAldaa(msg);
  }

  // ── Өгөгдөл ──

  /// Барилгын ирцийн хуваарь, тохиргоо
  static Future<Map<String, dynamic>?> barilgaAvya() async {
    final id = baiguullagiinId;
    if (id == null) return null;
    final data = await _get('/baiguullaga/$id');
    final barilguud = (data is Map ? data['barilguud'] as List? : null) ?? [];
    if (barilgiinId == null && barilguud.isNotEmpty && barilguud.first is Map) {
      _baiguullagiinBarilga = (barilguud.first as Map)['_id']?.toString();
    }
    for (final b in barilguud) {
      if (b is Map && b['_id']?.toString() == barilgiinId) {
        return Map<String, dynamic>.from(b);
      }
    }
    return null;
  }

  /// Барилгын оффисын байршил: {latitude, longitude, radiusMetr} эсвэл null (тохируулаагүй)
  static Future<Map<String, dynamic>?> officeBairshil() async {
    final data = await _post('/officeLocationAvya', {});
    final config = data is Map ? data['config'] : null;
    return config is Map ? Map<String, dynamic>.from(config) : null;
  }

  /// Утасны одоогийн байршил — зөвшөөрөлгүй/унтраалттай бол null (асуухгүй)
  static Future<Position?> minnyBairshil() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Өнөөдрийн ирц (амралттай бол `amralt` талбартай)
  static Future<Map<String, dynamic>?> unuudriinIrts() async {
    final data = await _post('/unuudriinIrtsAvya', {});
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  /// Миний нэг сарын ирцийн бичлэгүүд
  static Future<List<Map<String, dynamic>>> sarynIrts(DateTime sar) =>
      khugatsaanyIrts(DateTime(sar.year, sar.month, 1), DateTime(sar.year, sar.month + 1, 1));

  /// AI туслах (irtsBack POST /aiTuslakh, Gemini): хариуг хэсэг хэсгээр нь
  /// (stream) буцаана. Алдаа гарвал IrtsAldaa шиднэ.
  static Stream<String> aiTuslakh(List<Map<String, String>> messages) async* {
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse('$baseUrl/aiTuslakh'))
        ..headers.addAll(_headers)
        ..body = json.encode({
          'messages': messages,
          'khuudasniiNer': 'Гар утасны апп',
          if (barilgiinId != null) 'barilgiinId': barilgiinId,
        });
      final res = await client.send(req).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        final body = await res.stream.bytesToString();
        String msg = 'AI туслахтай холбогдож чадсангүй.';
        try {
          final j = json.decode(body);
          if (j is Map && j['message'] != null) msg = j['message'].toString();
        } catch (_) {}
        throw IrtsAldaa(msg);
      }
      yield* res.stream.transform(utf8.decoder).timeout(const Duration(seconds: 60));
    } finally {
      client.close();
    }
  }

  /// Миний ирц [ekh, tug) хугацаанд
  static Future<List<Map<String, dynamic>>> khugatsaanyIrts(DateTime ekh, DateTime tug) async {
    final data = await _get('/irts', {
      'query': {
        'ajiltniiId': ajiltan?.id,
        'baiguullagiinId': baiguullagiinId,
        'ognoo': {
          r'$gte': ekh.toUtc().toIso8601String(),
          r'$lt': tug.toUtc().toIso8601String(),
        },
      },
      'khuudasniiDugaar': '1',
      'khuudasniiKhemjee': '62',
    });
    final list = (data is Map ? data['jagsaalt'] as List? : null) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Чөлөө + амралтын миний хүсэлтүүд
  static Future<List<Map<String, dynamic>>> miniiKhuseltuud() async {
    final res = await Future.wait([
      _post('/miniiChuluuHuselt', {}),
      _post('/miniiAmraltHuselt', {}),
    ]);
    final jagsaalt = <Map<String, dynamic>>[
      for (final x in (res[0] as List? ?? []))
        {...Map<String, dynamic>.from(x as Map), 'turulKhuselt': 'chuluu'},
      for (final x in (res[1] as List? ?? []))
        {...Map<String, dynamic>.from(x as Map), 'turulKhuselt': 'amralt'},
    ];
    jagsaalt.sort((a, b) =>
        (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
    return jagsaalt;
  }

  // ── Удирдлага (Admin) ──

  /// Барилгын ажилтнууд (Admin-аас бусад)
  static Future<List<Map<String, dynamic>>> ajiltnuud() async {
    final data = await _get('/ajiltan', {
      'query': {
        'baiguullagiinId': baiguullagiinId,
        'barilguud': barilgiinId,
        'erkh': {r'$nin': ['Admin']},
      },
      'khuudasniiDugaar': '1',
      'khuudasniiKhemjee': '1000',
    });
    final list = (data is Map ? data['jagsaalt'] as List? : null) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Тухайн өдрийн бүх ажилтны ирц
  static Future<List<Map<String, dynamic>>> odriinBukhIrts(DateTime udur) async {
    final ekh = DateTime(udur.year, udur.month, udur.day);
    final data = await _get('/irts', {
      'query': {
        'baiguullagiinId': baiguullagiinId,
        'barilgiinId': barilgiinId,
        'ognoo': {
          r'$gte': ekh.toUtc().toIso8601String(),
          r'$lt': ekh.add(const Duration(days: 1)).toUtc().toIso8601String(),
        },
      },
      'khuudasniiDugaar': '1',
      'khuudasniiKhemjee': '1000',
    });
    final list = (data is Map ? data['jagsaalt'] as List? : null) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Барилгын бүх чөлөө/амралтын хүсэлт
  static Future<List<Map<String, dynamic>>> bukhKhuseltuud() async {
    final res = await Future.wait([
      _post('/chuluuHuseltJagsaalt', {}),
      _post('/amraltHuseltJagsaalt', {}),
    ]);
    final jagsaalt = <Map<String, dynamic>>[
      for (final x in (res[0] as List? ?? []))
        {...Map<String, dynamic>.from(x as Map), 'turulKhuselt': 'chuluu'},
      for (final x in (res[1] as List? ?? []))
        {...Map<String, dynamic>.from(x as Map), 'turulKhuselt': 'amralt'},
    ];
    jagsaalt.sort((a, b) =>
        (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()));
    return jagsaalt;
  }

  /// Хүсэлт шийдвэрлэх: tuluv = zuvshurulusen | tatgalzsan (татгалзвал шалтгаан заавал)
  static Future<void> khuseltShiidvel(Map h, String tuluv, {String? shaltgaan}) async {
    await _post(h['turulKhuselt'] == 'chuluu' ? '/chuluuHuseltZuvshurul' : '/amraltHuseltZuvshurul', {
      'huseltId': h['_id'],
      'tuluv': tuluv,
      if (shaltgaan != null) 'tatgalzsanShaltgaan': shaltgaan,
    });
  }

  // ── Мэдэгдэл (irts) ──

  /// irts-ийн удирдлагын мэдэгдлүүд (төгс ирц гэх мэт) — {jagsaalt, unshaagueToo}
  static Future<(List<Map<String, dynamic>>, int)> medegdluud() async {
    final data = await _post('/adminMedegdelJagsaaltAvya', {});
    if (data is! Map) return (<Map<String, dynamic>>[], 0);
    final list = (data['jagsaalt'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return (list, (data['unshaagueToo'] as num?)?.toInt() ?? 0);
  }

  static Future<void> medegdelUnshsan(String id) async {
    await _post('/adminMedegdelUnshsanBolgokh', {'adminMedegdelId': id});
  }

  /// Миний мэдэгдлүүд (хүсэлт зөвшөөрсөн/татгалзсан) — (жагсаалт, уншаагүй тоо)
  static Future<(List<Map<String, dynamic>>, int)> miniiMedegdluud() async {
    final data = await _post('/miniiMedegdelAvya', {});
    if (data is! Map) return (<Map<String, dynamic>>[], 0);
    final list = (data['jagsaalt'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return (list, (data['unshaagueToo'] as num?)?.toInt() ?? 0);
  }

  /// Миний мэдэгдлийг уншсан болгох (id эсвэл бүгдийг)
  static Future<void> miniiMedegdelUnshsan({String? id}) async {
    await _post('/miniiMedegdelUnshsan', id == null ? {'bukh': true} : {'id': id});
  }

  /// Миний батлагдсан цалингууд (сүүлийн 24 сар, шинэ нь эхэнд)
  static Future<List<Map<String, dynamic>>> miniiTsalin() async {
    final data = await _post('/miniiTsalin', {});
    return (data as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Үйлдэл ──

  /// Ирц бүртгүүлэх. turul: orokh | chuluunaasOrokh | tsainiiGarakh | tsainiiOrokh | garakh
  static Future<void> burtguulye(String turul) async {
    final bairshil = await _bairshilAvya();
    final orokh = turul == 'orokh' || turul == 'chuluunaasOrokh';
    final data = await _post(orokh ? '/irtsBurtguulye' : '/garsanTsagBurtguulye', {
      'turul': turul,
      'bairshil': ?bairshil,
      'tokhiromjiinMedeelel': {
        // Backend утасны төхөөрөмж эсэхийг энэ талбараар шалгана
        'userAgent': Platform.isIOS
            ? 'FSMApp (iPhone; iOS ${Platform.operatingSystemVersion}) Mobile'
            : 'FSMApp (Linux; Android ${Platform.operatingSystemVersion}) Mobile',
        'platform': Platform.operatingSystem,
      },
    });
    if (data is String && data != 'Amjilttai') throw IrtsAldaa(data);
  }

  static Future<void> chuluuKhuseltIlgeeye({
    required DateTime ognoo,
    DateTime? duusakhOgnoo,
    required String ekhlekhTsag,
    required String duusakhTsag,
    required String tailbar,
  }) async {
    await _post('/chuluuHuseltIlgeekh', {
      'ognoo': _udur(ognoo),
      'duusakhOgnoo': _udur(duusakhOgnoo ?? ognoo),
      'ekhlekhTsag': ekhlekhTsag,
      'duusakhTsag': duusakhTsag,
      'tailbar': tailbar,
    });
  }

  static Future<void> amraltKhuseltIlgeeye({
    required DateTime ekhlekhOgnoo,
    required DateTime duusakhOgnoo,
    required String turul, // eelj | uvchiin
    required String tailbar,
  }) async {
    await _post('/amraltHuseltIlgeekh', {
      'ekhlekhOgnoo': _udur(ekhlekhOgnoo),
      'duusakhOgnoo': _udur(duusakhOgnoo),
      'turul': turul,
      'tailbar': tailbar,
    });
  }

  static String _udur(DateTime d) =>
      DateTime(d.year, d.month, d.day).toUtc().toIso8601String();

  /// GPS — авч чадахгүй бол null (оффисын байршил тохируулаагүй барилгад
  /// backend шаардахгүй; тохируулсан бол backend өөрөө алдаа буцаана).
  static Future<Map<String, dynamic>?> _bairshilAvya() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
      };
    } catch (e) {
      debugPrint('[Irts] байршил авч чадсангүй: $e');
      return null;
    }
  }
}

class IrtsAldaa implements Exception {
  IrtsAldaa(this.message);
  final String message;
  @override
  String toString() => message;
}
