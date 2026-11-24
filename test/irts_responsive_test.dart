import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:work_ease/screens/irts_screen.dart';
import 'package:work_ease/services/auth_service.dart';
import 'package:work_ease/theme/app_theme.dart';

const _zuragAvakh = bool.fromEnvironment('IRTS_SCREENSHOT');

// Төхөөрөмжийн логик хэмжээ (dp)
const _tukhuurumjuud = <String, Size>{
  'galaxy_fold_evkhsen': Size(344, 882),
  'iphone_se': Size(375, 667),
  'iphone_15': Size(393, 852),
  'surface_duo_neg': Size(540, 720),
  'ipad_mini': Size(744, 1133),
  'ipad': Size(820, 1180),
  'galaxy_fold_delgesen': Size(884, 1104),
  'iphone_khevtee': Size(852, 393),
  'ipad_pro': Size(1024, 1366),
  'surface_duo_khoyor': Size(1114, 720),
};

DateTime _unuudur(int h, int m) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, h, m);
}

http.Response _json(Object o) => http.Response.bytes(
      utf8.encode(json.encode(o)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

final _client = MockClient((req) async {
  final p = req.url.path;
  final now = DateTime.now();
  if (p.startsWith('/baiguullaga/')) {
    return _json({
      'barilguud': [
        {
          '_id': 'b1',
          'ner': 'Төв оффис',
          'tokhirgoo': {'tsainiiTsagAshiglakhEsekh': true},
          'ajillakhUdruud': [
            {
              'neekhTsag': '09:00',
              'khaakhTsag': '18:00',
              'tsainiiNeekhTsag': '12:00',
              'tsainiiKhaakhTsag': '13:00',
              'udruud': ['0', '1', '2', '3', '4', '5', '6'],
            }
          ],
        }
      ],
    });
  }
  if (p == '/unuudriinIrtsAvya') {
    return _json({
      'irsenTsag': _unuudur(9, 14).toUtc().toIso8601String(),
      'tsainiiGarsanTsag': _unuudur(12, 4).toUtc().toIso8601String(),
      'tsainiiIrsenTsag': _unuudur(12, 57).toUtc().toIso8601String(),
      'khotsorsonMinut': 14,
      'tuluv': 'khotsorson',
    });
  }
  if (p == '/irts') {
    final tuluvuud = ['kheviin', 'kheviin', 'khotsorson', 'kheviin', 'chuluu', 'kheviin', 'tasalsan', 'amralt', 'kheviin', 'hagas'];
    return _json({
      'jagsaalt': [
        for (var d = 1; d < now.day; d++)
          {
            'ognoo': DateTime(now.year, now.month, d).toUtc().toIso8601String(),
            'tuluv': tuluvuud[d % tuluvuud.length],
            'khotsorsonMinut': tuluvuud[d % tuluvuud.length] == 'khotsorson' ? 9 : 0,
          }
      ],
    });
  }
  if (p == '/miniiChuluuHuselt') {
    return _json([
      {
        '_id': 'c1',
        'ognoo': now.toUtc().toIso8601String(),
        'ekhlekhTsag': '14:00',
        'duusakhTsag': '16:30',
        'tailbar': 'Эмнэлэгт үзүүлэх цагтай',
        'tuluv': 'huvlaj_baina',
        'createdAt': now.toIso8601String(),
      },
    ]);
  }
  if (p == '/miniiAmraltHuselt') {
    return _json([
      {
        '_id': 'a1',
        'ekhlekhOgnoo': now.add(const Duration(days: 10)).toUtc().toIso8601String(),
        'duusakhOgnoo': now.add(const Duration(days: 14)).toUtc().toIso8601String(),
        'turul': 'eelj',
        'tailbar': 'Гэр бүлийн аялал',
        'tuluv': 'tatgalzsan',
        'tatgalzsanShaltgaan': 'Тэр долоо хоногт ачаалал их байна',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ]);
  }
  return http.Response('not found', 404);
});

Future<void> _fontAchaallay() async {
  Future<void> load(String family, String path) async {
    final f = File(path);
    if (!f.existsSync()) return;
    final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }

  await load('Roboto', '/System/Library/Fonts/Supplemental/Arial.ttf');
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  await load('MaterialIcons', '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
}

Widget _app() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColorScheme.light.brandGreen),
        extensions: const [AppColorScheme.light],
      ),
      home: const IrtsScreen(),
    );

/// Бүртгэлийн товчны импульс тасралтгүй тул тогтмол хугацаа урагшлуулна
Future<void> _tog(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(() async {
    if (_zuragAvakh) await _fontAchaallay();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test',
      'auth_user': json.encode({
        'id': 'u1',
        'ner': 'Болд',
        'baiguullagaId': 'o1',
        'barilguud': ['b1'],
      }),
    });
    await AuthService.restoreSession();
  });

  for (final e in _tukhuurumjuud.entries) {
    testWidgets('Ирц: ${e.key} (${e.value.width.toInt()}×${e.value.height.toInt()}) overflow-гүй', (tester) async {
      tester.view.physicalSize = e.value * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await http.runWithClient(() async {
        await tester.pumpWidget(_app());
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }, () => _client);
      await _tog(tester);

      // Утсан дээр самбар хураагдсан: дээш чирэхэд дэлгэрэнгүй харагдана
      expect(find.text('Цаг бүртгэл'), findsOneWidget);
      if (_zuragAvakh) {
        await expectLater(find.byType(IrtsScreen), matchesGoldenFile('irts_goldens/${e.key}_khuraasan.png'));
      }
      if (e.value.width < 720 && e.value.width <= e.value.height * 1.3) {
        await tester.drag(find.text('Цаг бүртгэл'), const Offset(0, -500));
        await _tog(tester);
      }
      expect(find.text('Ирсэн цаг'), findsOneWidget);
      expect(find.text('Цайнд гарах').evaluate().isNotEmpty || find.text('Гарах').evaluate().isNotEmpty ||
          find.text('Орох').evaluate().isNotEmpty || find.text('Цайнаас орох').evaluate().isNotEmpty ||
          find.text('Өнөөдрийн ажил дууссан').evaluate().isNotEmpty, isTrue);
      if (_zuragAvakh) {
        await expectLater(find.byType(IrtsScreen), matchesGoldenFile('irts_goldens/${e.key}_sar.png'));
      }

      // Хүсэлт таб
      await tester.tap(find.text('Хүсэлт'));
      await _tog(tester);
      expect(find.text('Эмнэлэгт үзүүлэх цагтай'), findsOneWidget);
      if (_zuragAvakh) {
        await expectLater(find.byType(IrtsScreen), matchesGoldenFile('irts_goldens/${e.key}_khuselt.png'));
      }

      // Хүсэлт илгээх цонх
      await tester.tap(find.text('Хүсэлт илгээх'));
      await _tog(tester);
      expect(find.text('Хүсэлтийн төрөл сонгох'), findsOneWidget);
      if (_zuragAvakh) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('irts_goldens/${e.key}_form.png'));
      }

      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Ирц: Galaxy Fold (эвхсэн) том фонттой overflow-гүй', (tester) async {
    tester.view.physicalSize = const Size(344, 882) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await http.runWithClient(() async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }, () => _client);
    await _tog(tester);
    expect(find.text('Ирсэн цаг'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
