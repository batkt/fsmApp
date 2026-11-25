import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:work_ease/screens/login_screen.dart';
import 'package:work_ease/theme/app_theme.dart';

const _zuragAvakh = bool.fromEnvironment('LOGIN_SCREENSHOT');

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

class _FakeAuth extends LocalAuthPlatform with MockPlatformInterfaceMixin {
  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async =>
      false;
  @override
  Future<bool> deviceSupportsBiometrics() async => true;
  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => [BiometricType.face];
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<bool> stopAuthentication() async => true;
}

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

Widget _app({bool dark = false}) {
  final c = dark ? AppColorScheme.dark : AppColorScheme.light;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.brandGreen,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      extensions: [c],
    ),
    home: LoginScreen(onLoggedIn: () {}),
  );
}

/// Hero тасралтгүй хөдөлдөг тул pumpAndSettle биш, тогтмол хугацаа урагшлуулна
Future<void> _tog(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    if (_zuragAvakh) await _fontAchaallay();
    LocalAuthPlatform.instance = _FakeAuth();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'WorkEase',
      packageName: 'mn.zevtabs.workease',
      version: '1.0.8',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final e in _tukhuurumjuud.entries) {
    testWidgets('Нэвтрэх: ${e.key} overflow-гүй', (tester) async {
      tester.view.physicalSize = e.value * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app());
      await _tog(tester);
      expect(find.text('Нэвтрэх нэр'), findsOneWidget);
      if (_zuragAvakh) {
        await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_goldens/${e.key}.png'));
      }

      // Хоосон илгээхэд алдаа харагдана
      await tester.ensureVisible(find.text('Нэвтрэх').last);
      await _tog(tester);
      await tester.tap(find.text('Нэвтрэх').last);
      await _tog(tester);
      expect(find.text('Нууц кодыг оруулна уу'), findsOneWidget);

      // Нэр + 2 орон бөглөсөн төлөв
      await tester.enterText(find.byType(TextFormField).first, 'bold');
      await tester.enterText(find.byType(TextField).last, '12');
      await _tog(tester);
      if (_zuragAvakh) {
        await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_goldens/${e.key}_bugluj.png'));
      }
    });
  }

  testWidgets('Нэвтрэх: Galaxy Fold эвхсэн, том фонт, харанхуй горим', (tester) async {
    tester.view.physicalSize = const Size(344, 882) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app(dark: true));
    await _tog(tester);
    expect(find.text('Нэвтрэх нэр'), findsOneWidget);
    if (_zuragAvakh) {
      await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_goldens/fold_tom_font_dark.png'));
    }
  });

  testWidgets('Нэвтрэх: хөдөлгөөн багасгах горимд animation зогсоно', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle(); // давталт зогссон тул тогтоно
    expect(find.text('Нэвтрэх нэр'), findsOneWidget);
    expect(find.text('Нэвтрэх'), findsWidgets);
  });

  for (final e in _tukhuurumjuud.entries) {
  testWidgets('Нэвтрэх: hero модулиуд ээлжлэн солигдоно, ${e.key}', (tester) async {
    tester.view.physicalSize = e.value * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.bySemanticsLabel('Төлөвлөгөө & Гүйцэтгэл'), findsOneWidget);
    if (_zuragAvakh) await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_goldens/scene_fsm_${e.key}.png'));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Хүний нөөцийн менежмент'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Цагийн бүртгэл'), findsOneWidget);
    if (_zuragAvakh) await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_goldens/scene_irts_${e.key}.png'));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Цалингийн тооцоолол'), findsOneWidget);
    if (_zuragAvakh) await expectLater(find.byType(LoginScreen), matchesGoldenFile('login_goldens/scene_tsalin_${e.key}.png'));
  });
  }
}
