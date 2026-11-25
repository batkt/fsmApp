import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _brand = Color(0xFF315BB0);
const _asuusanTulkhuur = 'zuvshuurul_asuusan_v1';

/// Зөвшөөрлийн бодит төлөв (утасны тохиргооноос)
enum ZTuluv { zuvshuursun, asuuj_bolno, tokhirgoond, unraasan }

Future<ZTuluv> bairshliinTuluv() async {
  if (!await Geolocator.isLocationServiceEnabled()) return ZTuluv.unraasan;
  final p = await Geolocator.checkPermission();
  return switch (p) {
    LocationPermission.always || LocationPermission.whileInUse => ZTuluv.zuvshuursun,
    LocationPermission.deniedForever => ZTuluv.tokhirgoond,
    _ => ZTuluv.asuuj_bolno,
  };
}

Future<ZTuluv> medegdliinTuluv() async {
  final s = await Permission.notification.status;
  if (s.isGranted || s.isProvisional) return ZTuluv.zuvshuursun;
  if (s.isPermanentlyDenied || s.isRestricted) return ZTuluv.tokhirgoond;
  return ZTuluv.asuuj_bolno;
}

/// Анх нэвтэрсний дараа: байршил, мэдэгдлийн зөвшөөрлийг тайлбартай асууна.
/// Утасны тохиргоонд аль хэдийн зөвшөөрсөн бол алгасна; хаасан бол Тохиргоо нээнэ.
class ZuvshuurulScreen extends StatefulWidget {
  const ZuvshuurulScreen({super.key});

  static Future<void> shaardlagatai(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_asuusanTulkhuur) ?? false) return;
    await prefs.setBool(_asuusanTulkhuur, true);
    try {
      final b = await bairshliinTuluv();
      final m = await medegdliinTuluv();
      if (b == ZTuluv.zuvshuursun && m == ZTuluv.zuvshuursun) return;
    } catch (_) {}
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ZuvshuurulScreen()),
    );
  }

  @override
  State<ZuvshuurulScreen> createState() => _ZuvshuurulScreenState();
}

class _Alkham {
  const _Alkham(this.garchig, this.icon, this.ner, this.tailbar, this.tuluv, this.asuukh, this.tokhirgoo);
  final String garchig;
  final IconData icon;
  final String ner;
  final String tailbar;
  final Future<ZTuluv> Function() tuluv;
  final Future<void> Function() asuukh;
  final Future<void> Function(ZTuluv) tokhirgoo;
}

class _ZuvshuurulScreenState extends State<ZuvshuurulScreen> with WidgetsBindingObserver {
  int _i = 0;
  bool _asuuj = false;
  ZTuluv? _tuluv;

  late final _alkhmuud = <_Alkham>[
    _Alkham(
      'Байршлын зөвшөөрөл',
      Icons.location_on_outlined,
      'Байршил',
      'Ирц бүртгүүлэхэд та ажлын байрандаа байгааг шалгахын тулд байршлыг ашиглана. Зөвхөн апп нээлттэй үед ашиглагдана.',
      bairshliinTuluv,
      () async => Geolocator.requestPermission(),
      (t) async => t == ZTuluv.unraasan ? Geolocator.openLocationSettings() : Geolocator.openAppSettings(),
    ),
    _Alkham(
      'Мэдэгдэл авах',
      Icons.notifications_none_rounded,
      'Мэдэгдэл',
      'Та энэхүү зөвшөөрлийг олгосноор цагийн сануулга, хүсэлтийн хариу болон байгууллагаас ирсэн чухал мэдээллийг цаг алдалгүй авна.',
      medegdliinTuluv,
      () async => Permission.notification.request(),
      (_) async => openAppSettings(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shinechle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Тохиргооноос буцаж ирэхэд төлөвийг дахин уншина
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _shinechle();
  }

  Future<void> _shinechle() async {
    ZTuluv t;
    try {
      t = await _alkhmuud[_i].tuluv();
    } catch (_) {
      t = ZTuluv.asuuj_bolno;
    }
    if (mounted) setState(() => _tuluv = t);
  }

  Future<void> _gol() async {
    final a = _alkhmuud[_i];
    final t = _tuluv;
    if (t == ZTuluv.zuvshuursun) return _daraakh();
    setState(() => _asuuj = true);
    try {
      if (t == ZTuluv.tokhirgoond || t == ZTuluv.unraasan) {
        await a.tokhirgoo(t!);
      } else {
        await a.asuukh();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _asuuj = false);
    await _shinechle();
    // Системийн цонхоор зөвшөөрсөн/татгалзсан бол дараагийн алхам руу
    if (t == ZTuluv.asuuj_bolno && _tuluv != ZTuluv.tokhirgoond) _daraakh();
  }

  void _daraakh() {
    if (_i < _alkhmuud.length - 1) {
      setState(() {
        _i++;
        _tuluv = null;
      });
      _shinechle();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = _alkhmuud[_i];
    final (tovch, tuluvTekst, tuluvUngu) = switch (_tuluv) {
      ZTuluv.zuvshuursun => ('Үргэлжлүүлэх', 'Зөвшөөрсөн', _brand),
      ZTuluv.tokhirgoond => ('Тохиргоо нээх', 'Утасны тохиргоонд хаалттай байна', const Color(0xFFD97706)),
      ZTuluv.unraasan => ('Байршил асаах', 'Утасны байршил унтраалттай байна', const Color(0xFFD97706)),
      _ => ('Зөвшөөрөх', null, null),
    };
    return Scaffold(
      backgroundColor: c.cardBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var k = 0; k < _alkhmuud.length; k++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: k == _i ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: k == _i ? _brand : c.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ]),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(key: ValueKey(_i), children: [
                    Text(a.garchig,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, letterSpacing: -0.4, color: c.primary)),
                    const SizedBox(height: 40),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(color: _brand.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: Icon(a.icon, size: 42, color: _brand),
                    ),
                    const SizedBox(height: 10),
                    Text(a.ner, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary)),
                    const SizedBox(height: 28),
                    Text(a.tailbar, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5, color: c.mutedForeground)),
                    if (tuluvTekst != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: tuluvUngu!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_tuluv == ZTuluv.zuvshuursun ? Icons.check_circle_rounded : Icons.settings_rounded,
                              size: 16, color: tuluvUngu),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(tuluvTekst, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: tuluvUngu)),
                          ),
                        ]),
                      ),
                    ],
                  ]),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _asuuj || _tuluv == null ? null : _gol,
                    style: FilledButton.styleFrom(backgroundColor: _brand, shape: const StadiumBorder()),
                    child: Text(tovch, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _asuuj ? null : _daraakh,
                  style: TextButton.styleFrom(foregroundColor: c.mutedForeground),
                  child: const Text('Дараа', style: TextStyle(fontSize: 15)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
