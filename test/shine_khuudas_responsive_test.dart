import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:work_ease/screens/ajlyn_khuvaari_screen.dart';
import 'package:work_ease/screens/irts_tailan_screen.dart';
import 'package:work_ease/screens/nuur_screen.dart';
import 'package:work_ease/screens/profail_tses_screen.dart';
import 'package:work_ease/screens/root_screen.dart';
import 'package:work_ease/screens/tsalin_screen.dart';
import 'package:work_ease/screens/udirdlaga_screen.dart';
import 'package:work_ease/services/auth_service.dart';
import 'package:work_ease/theme/app_theme.dart';
import 'package:work_ease/widgets/medegdel_khonkh.dart';

const _zuragAvakh = bool.fromEnvironment('SHINE_SCREENSHOT');

const _tukhuurumjuud = <String, Size>{
  'galaxy_fold_evkhsen': Size(344, 882),
  'iphone_se': Size(375, 667),
  'iphone_15': Size(393, 852),
  'surface_duo_neg': Size(540, 720),
  'ipad': Size(820, 1180),
  'galaxy_fold_delgesen': Size(884, 1104),
  'iphone_khevtee': Size(852, 393),
  'ipad_pro': Size(1024, 1366),
};

http.Response _json(Object o) => http.Response.bytes(utf8.encode(json.encode(o)), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

String _iso(DateTime d) => d.toUtc().toIso8601String();

final _client = MockClient((req) async {
  // irts хэрэглэгч irts.zevtabs.mn/api руу хандана
  final p = req.url.path.replaceFirst(RegExp(r'^/api'), '');
  final now = DateTime.now();
  DateTime t(int d, int h, int m) => DateTime(now.year, now.month, d, h, m);
  if (p.startsWith('/baiguullaga/')) {
    return _json({
      'barilguud': [
        {
          '_id': 'b1',
          'ner': 'Төв оффис',
          'ajillakhUdruud': [
            {
              'neekhTsag': '08:00',
              'khaakhTsag': '17:00',
              'tsainiiNeekhTsag': '12:00',
              'tsainiiKhaakhTsag': '13:00',
              'udruud': ['1', '2', '3', '4', '5'],
            }
          ],
        }
      ],
    });
  }
  if (p == '/ajiltan') {
    return _json({
      'jagsaalt': [
        for (final (i, n) in ['Хонгорзул', 'Ариунбуян', 'Оюунбат', 'Отгонбилэг', 'Энх-Амар'].indexed)
          {'_id': 'a$i', 'ner': n, 'ovog': 'Батболд'}
      ],
    });
  }
  if (p == '/irts') {
    final odriin = req.url.queryParameters['query']?.contains('ajiltniiId') != true;
    if (odriin) {
      return _json({
        'jagsaalt': [
          {'ajiltniiId': 'a0', 'irsenTsag': _iso(t(now.day, 7, 49)), 'tuluv': 'kheviin'},
          {'ajiltniiId': 'a1', 'irsenTsag': _iso(t(now.day, 8, 19)), 'tuluv': 'khotsorson', 'khotsorsonMinut': 19},
          {'ajiltniiId': 'a2', 'tuluv': 'chuluu', 'chuluuniiTurul': []},
        ],
      });
    }
    return _json({
      'jagsaalt': [
        for (var d = 1; d < now.day; d++)
          if (DateTime(now.year, now.month, d).weekday <= 5)
            {
              'ognoo': _iso(DateTime(now.year, now.month, d)),
              'irsenTsag': _iso(t(d, 8, d % 3 == 0 ? 12 : 0)),
              'yawsanTsag': _iso(t(d, 17, 5)),
              'ajillasanMinut': 470,
              'khotsorsonMinut': d % 3 == 0 ? 12 : 0,
              'tuluv': d % 3 == 0 ? 'khotsorson' : 'kheviin',
            }
      ],
    });
  }
  if (p == '/chuluuHuseltJagsaalt' || p == '/miniiChuluuHuselt') {
    return _json([
      {
        '_id': 'c1',
        'ajiltniiNer': 'Б.Оюунбат',
        'ognoo': _iso(now),
        'ekhlekhTsag': '14:00',
        'duusakhTsag': '16:30',
        'tailbar': 'Эмнэлэгт үзүүлэх',
        'tuluv': 'huvlaj_baina',
        'createdAt': now.toIso8601String(),
      },
    ]);
  }
  if (p == '/amraltHuseltJagsaalt' || p == '/miniiAmraltHuselt') {
    return _json([
      {
        '_id': 'a1',
        'ajiltniiNer': 'Б.Энх-Амар',
        'ekhlekhOgnoo': _iso(now.add(const Duration(days: 7))),
        'duusakhOgnoo': _iso(now.add(const Duration(days: 11))),
        'turul': 'eelj',
        'tuluv': 'zuvshurulusen',
        'zuvshuruluusenAjiltniiNer': 'Админ',
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
    ]);
  }
  if (p == '/miniiTsalin') {
    return _json([
      {
        '_id': 't1', 'jil': now.year, 'sar': now.month, 'undsenTsalin': 2000000, 'fondTsag': 160, 'ajillasanTsag': 144,
        'iluuTsag': 4, 'bodogdsonTsalin': 1800000, 'iluuTsagiinTsalin': 75000, 'khotsroltSuutgal': 6250,
        'nemegdeluud': [{'ner': 'Шагнал', 'dun': 100000}], 'suutgaluud': [{'ner': 'Урьдчилгаа', 'dun': 50000}],
        'olgovolZokhikh': 1968750, 'ndsh': 226406, 'khkhoat': 154234, 'gartOlgokh': 1538110, 'tuluv': 'batlagdsan',
      },
    ]);
  }
  if (p == '/miniiMedegdelAvya') {
    return _json({
      'jagsaalt': [
        {'_id': 'm1', 'title': 'Чөлөөний хүсэлт зөвшөөрөгдлөө', 'message': '11.24 чөлөөний хүсэлт тань зөвшөөрөгдлөө', 'tuluv': 'zuvshurulusen', 'unshsan': false, 'createdAt': _iso(now)},
        {'_id': 'm2', 'title': 'Амралтын хүсэлт татгалзлаа', 'message': 'Шалтгаан: ачаалал их', 'tuluv': 'tatgalzsan', 'unshsan': false, 'createdAt': _iso(now)},
      ],
      'unshaagueToo': 2,
    });
  }
  return http.Response('{}', 404);
});

Future<void> _fontAchaallay() async {
  Future<void> load(String family, String path) async {
    final f = File(path);
    if (!f.existsSync()) return;
    await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
  }

  await load('Roboto', '/System/Library/Fonts/Supplemental/Arial.ttf');
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  await load('MaterialIcons', '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
}

Widget _app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColorScheme.light.brandGreen),
        extensions: const [AppColorScheme.light],
      ),
      home: home,
    );

final _khuudsuud = <String, Widget Function()>{
  'nuur': () => NuurScreen(irtsKharagdakh: true, daalgavarKharagdakh: true, onModulNeey: (_) {}),
  'tailan': () => const IrtsTailanScreen(),
  'khuvaari': () => const AjlynKhuvaariScreen(),
  'udirdlaga': () => const UdirdlagaScreen(),
  'profail': () => ProfailTsesScreen(onLogout: () {}, irtsKharagdakh: true),
  'tsalin': () => const TsalinScreen(),
};

void main() {
  setUpAll(() async {
    if (_zuragAvakh) await _fontAchaallay();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test',
      'auth_user': json.encode({
        'id': 'u1',
        'ner': 'Болорхүү',
        'ovog': 'Нямаа',
        'baiguullagaId': 'o1',
        'barilguud': ['b1'],
        'role': 'Admin',
        'system': 'irts',
      }),
    });
    await AuthService.restoreSession();
  });

  for (final kh in _khuudsuud.entries) {
    for (final e in _tukhuurumjuud.entries) {
      testWidgets('${kh.key}: ${e.key} overflow-гүй', (tester) async {
        tester.view.physicalSize = e.value * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await http.runWithClient(() async {
          await tester.pumpWidget(_app(kh.value()));
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
        }, () => _client);
        await tester.pump(const Duration(milliseconds: 500));
        if (_zuragAvakh) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('shine_goldens/${kh.key}_${e.key}.png'));
        }
        if (kh.key == 'profail') {
          // Түгээмэл асуулт доод цонхонд алдаагүй нээгдэнэ
          await tester.scrollUntilVisible(find.text('Түгээмэл асуулт'), 200);
          await tester.tap(find.text('Түгээмэл асуулт'));
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        }
        if (kh.key == 'udirdlaga') {
          await tester.tap(find.text('Хүсэлт'));
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text('Зөвшөөрөх'), findsOneWidget);
          if (_zuragAvakh) {
            await expectLater(find.byType(MaterialApp), matchesGoldenFile('shine_goldens/${kh.key}_khuselt_${e.key}.png'));
          }
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('Хонх: шийдвэрийн мэдэгдэл уншаагүйн тоотой харагдана', (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(_app(const Scaffold(body: Center(child: MedegdelKhonkh()))));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.descendant(of: find.byType(MedegdelKhonkh), matching: find.text('2')), findsOneWidget);
      await tester.tap(find.byType(MedegdelKhonkh));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, () => _client);
    expect(find.text('Чөлөөний хүсэлт зөвшөөрөгдлөө'), findsOneWidget);
    expect(find.text('Амралтын хүсэлт татгалзлаа'), findsOneWidget);
    expect(find.text('Бүгдийг уншсан'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('Цалин: zevtabs-д сонгосон үед л харагдана', () {
    const m = FsmModul(Icons.money, 'Цалин', SizedBox(),
        zevtabsShaardlagatai: true, systemuud: {'irts': ['/khyanalt/tsalin']});
    AuthUser u({String role = '', List<String>? org, List<String> erkh = const [], String system = 'irts'}) => AuthUser(
          id: 'u', ner: 'n', ovog: '', register: '', utas: '', albanTushaal: '', baiguullagaId: 'o', baiguullagaNer: '',
          barilguud: const [], role: role, tsonkhniiErkhuud: erkh, system: system, moduluud: org);
    expect(m.kharagdakh(u(role: 'Admin', org: null)), isFalse, reason: 'байгууллагын цонх мэдэгдэхгүй');
    expect(m.kharagdakh(u(role: 'Admin', org: ['/khyanalt/irts/jagsaalt'])), isFalse, reason: 'zevtabs-д сонгоогүй');
    expect(m.kharagdakh(u(role: 'Admin', org: ['/khyanalt/tsalin'])), isTrue, reason: 'сонгосон, Admin');
    expect(m.kharagdakh(u(org: ['/khyanalt/tsalin'])), isFalse, reason: 'ажилтанд эрх олгоогүй');
    expect(m.kharagdakh(u(org: ['/khyanalt/tsalin'], erkh: ['/khyanalt/tsalin'])), isTrue, reason: 'ажилтанд эрхтэй');
    expect(m.kharagdakh(u(role: 'Admin', system: 'fsm', org: ['/khyanalt/uilchilgee/tsalin'])), isFalse, reason: 'FSM-д цалин байхгүй');
  });
}
