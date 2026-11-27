import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/irts_service.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../utils/irts_logic.dart';
import '../widgets/medegdel_khonkh.dart';
import 'irts_tailan_screen.dart';
import 'profail_tses_screen.dart';

const _brand = Color(0xFFF18F02);

/// Нүүр хуудас: мэндчилгээ, сарын модулиудын товч мэдээлэл.
class NuurScreen extends StatefulWidget {
  const NuurScreen({
    super.key,
    required this.irtsKharagdakh,
    required this.daalgavarKharagdakh,
    required this.onModulNeey,
    this.tsalinKharagdakh = false,
    this.busadModuluud = const [],
    this.onLogout,
  });

  /// Доод цэсэнд багтаагүй модулиуд (Удирдлага, Түүх, Чат...) — Нүүрт үйлчилгээ болж харагдана
  final List<(IconData, String)> busadModuluud;

  /// Ирц модульд эрхтэй эсэх (хуваарь, ирц, хүсэлтийн хэсгүүд)
  final bool irtsKharagdakh;
  final bool daalgavarKharagdakh;
  /// zevtabs-д Цалин модуль сонгогдсон эсэх
  final bool tsalinKharagdakh;
  /// Модулийн таб руу шилжих ('Ирц', 'Даалгавар' гэх мэт)
  final ValueChanged<String> onModulNeey;
  final VoidCallback? onLogout;

  @override
  State<NuurScreen> createState() => _NuurScreenState();
}

class _NuurScreenState extends State<NuurScreen> {
  Map<String, dynamic>? _barilga;
  List<Map<String, dynamic>> _sarynIrts = [];
  int? _khuleegdejBui;
  int? _idevkhteiDaalgavar;
  List<ApiTask>? _ajluud;
  bool _achaallaj = true;

  @override
  void initState() {
    super.initState();
    _achaallaya();
  }

  /// Нэг хэсэг алдаа гарвал бусад нь ачаалагдсаар байна ("—" харагдана)
  static Future<void> _ayulgui(Future<void> Function() f) async {
    try {
      await f();
    } catch (_) {}
  }

  Future<void> _achaallaya() async {
    final now = DateTime.now();
    if (widget.irtsKharagdakh) {
      // Барилга эхэлж (Admin бол байгууллагын эхний барилга сонгогдоно)
      await _ayulgui(() async => _barilga = await IrtsService.barilgaAvya());
    }
    await Future.wait([
      if (widget.irtsKharagdakh && IrtsService.barilgiinId != null) ...[
        _ayulgui(() async => _sarynIrts = await IrtsService.sarynIrts(DateTime(now.year, now.month))),
        _ayulgui(() async {
          final v = await IrtsService.miniiKhuseltuud();
          _khuleegdejBui = v.where((h) => h['tuluv'] == 'huvlaj_baina').length;
        }),
      ],
      if (widget.daalgavarKharagdakh)
        _ayulgui(() async {
          final v = await TaskService.myTasks();
          _ajluud = v;
          _idevkhteiDaalgavar = v.where((t) => t.tuluv != 'duussan').length;
        }),
    ]);
    if (mounted) setState(() => _achaallaj = false);
  }

  String get _mendchilgee {
    final h = DateTime.now().hour;
    if (h < 12) return 'Өглөөний мэнд';
    if (h < 18) return 'Өдрийн мэнд';
    return 'Оройн мэнд';
  }

  static const _garag = ['Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба', 'Ням'];

  /// Үйлчилгээний хавтангийн өнгө (нэрээр), бусад нь дарааллаар
  static const _moduliinUngu = <String, List<Color>>{
    'Удирдлага': [Color(0xFF2DD4BF), Color(0xFF0F8F86)],
    'Түүх': [Color(0xFFFBBF24), Color(0xFFEA8A0C)],
    'Чат': [Color(0xFF38BDF8), Color(0xFF0369A1)],
    'Гүйцэтгэл': [Color(0xFFFB7185), Color(0xFFE11D48)],
  };
  static const _nemeltUngu = [
    [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    [Color(0xFF34D399), Color(0xFF059669)],
    [Color(0xFFF472B6), Color(0xFFDB2777)],
  ];

  void _tailanNeey() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const IrtsTailanScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = AuthService.currentUser;
    final now = DateTime.now();
    final dun = sarynDunTootsoo(_sarynIrts, _barilga, DateTime(now.year, now.month));
    final deedZai = MediaQuery.paddingOf(context).top;

    // Үйлчилгээнүүд (апп-лаунчер маягийн сүлжээ)
    final uilchilgee = <_Uilchilgee>[
      if (widget.irtsKharagdakh)
        _Uilchilgee(Icons.how_to_reg_rounded, 'Ирц', const [Color(0xFF38BDF8), Color(0xFF0284C7)],
            () => widget.onModulNeey('Ирц')),
      if (widget.irtsKharagdakh)
        _Uilchilgee(Icons.bar_chart_rounded, 'Цаг бүртгэл', const [Color(0xFFF6B003), _brand], _tailanNeey),
      if (widget.irtsKharagdakh)
        _Uilchilgee(Icons.send_rounded, 'Хүсэлт', const [Color(0xFFFBBF24), Color(0xFFF97316)],
            () => widget.onModulNeey('Ирц'),
            too: _khuleegdejBui ?? 0),
      if (widget.daalgavarKharagdakh)
        _Uilchilgee(Icons.checklist_rounded, 'Даалгавар', const [Color(0xFF60A5FA), Color(0xFF2563EB)],
            () => widget.onModulNeey('Даалгавар'),
            too: _idevkhteiDaalgavar ?? 0),
      if (widget.tsalinKharagdakh)
        _Uilchilgee(Icons.account_balance_wallet_rounded, 'Цалин', const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
            () => widget.onModulNeey('Цалин')),
      for (var i = 0; i < widget.busadModuluud.length; i++)
        _Uilchilgee(
          widget.busadModuluud[i].$1,
          widget.busadModuluud[i].$2,
          _moduliinUngu[widget.busadModuluud[i].$2] ?? _nemeltUngu[i % _nemeltUngu.length],
          () => widget.onModulNeey(widget.busadModuluud[i].$2),
        ),
    ];

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: RefreshIndicator(
        color: _brand,
        onRefresh: _achaallaya,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ── Градиент толгой ──
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF6B003), _brand, Color(0xFFE67E00)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Stack(children: [
                // Чимэглэлийн тойргууд
                Positioned(right: -40, top: -30, child: _Toirog(160, 0.10)),
                Positioned(right: 60, top: deedZai + 70, child: _Toirog(70, 0.08)),
                Positioned(left: -30, bottom: -50, child: _Toirog(120, 0.07)),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, deedZai + 12, 20, widget.irtsKharagdakh ? 86 : 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Semantics(
                        button: true,
                        label: 'Профайл',
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProfailTsesScreen(
                              onLogout: widget.onLogout ?? () {},
                              irtsKharagdakh: widget.irtsKharagdakh,
                            ),
                          )),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: CircleAvatar(
                              radius: 21,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                _tovchNer(user?.ner ?? ''),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_mendchilgee, style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF))),
                          Text(
                            _bukhNer(user),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ]),
                      ),
                      const MedegdelKhonkh(tsagaanDeer: false),
                    ]),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('${_garag[now.weekday - 1]}, ${now.month}-р сарын ${now.day}',
                            style: const TextStyle(fontSize: 13, color: Colors.white)),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),

            // ── Энэ сарын ирц: толгой дээр хөвөх карт ──
            if (widget.irtsKharagdakh)
              Transform.translate(
                offset: const Offset(0, -64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    color: c.cardBackground,
                    elevation: 0,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _tailanNeey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: c.border),
                          boxShadow: [
                            BoxShadow(color: _brand.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Row(children: [
                          _KhuviTsagirag(khuvi: _achaallaj ? 0 : dun.khuvi),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(
                                  child: Text('Энэ сарын ирц',
                                      style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 20, color: c.mutedForeground),
                              ]),
                              const SizedBox(height: 6),
                              _MiniStat(
                                icon: Icons.schedule_rounded,
                                ungu: const Color(0xFF10B981),
                                ner: 'Ажилласан',
                                utga: _achaallaj ? '…' : tsagMinutTekst(dun.ajillasan),
                              ),
                              _MiniStat(
                                icon: Icons.event_available_rounded,
                                ungu: _brand,
                                ner: 'Ирсэн өдөр',
                                utga: _achaallaj ? '…' : '${dun.irsenUdur} / ${dun.ajlynUdur}',
                              ),
                              _MiniStat(
                                icon: Icons.warning_amber_rounded,
                                ungu: dun.khotsorson == 0 ? const Color(0xFF10B981) : const Color(0xFFE5484D),
                                ner: 'Хоцролт',
                                utga: _achaallaj
                                    ? '…'
                                    : dun.khotsorson == 0
                                        ? 'Байхгүй'
                                        : tsagMinutTekst(dun.khotsorson),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),

            Transform.translate(
              offset: Offset(0, widget.irtsKharagdakh ? -48 : 16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // ── Анхаарах зүйлс ──
                  // ── Ажил менежмент: өнөөдрийн ажлын самбар ──
                  if (widget.daalgavarKharagdakh) ...[
                    _AjilKart(ajluud: _ajluud, achaallaj: _achaallaj, onTap: () => widget.onModulNeey('Даалгавар')),
                    const SizedBox(height: 18),
                  ],
                  if ((_khuleegdejBui ?? 0) > 0) ...[
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if ((_khuleegdejBui ?? 0) > 0)
                        _AnkhaarPill(
                          icon: Icons.hourglass_top_rounded,
                          text: '$_khuleegdejBui хүсэлт хүлээгдэж буй',
                          ungu: const Color(0xFFF97316),
                          onTap: () => widget.onModulNeey('Ирц'),
                        ),
                    ]),
                    const SizedBox(height: 18),
                  ],
                  // ── Үйлчилгээ ──
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('Үйлчилгээ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary)),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    decoration: BoxDecoration(
                      color: c.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border),
                    ),
                    child: LayoutBuilder(builder: (context, box) {
                      final bagana = box.maxWidth >= 560 ? 6 : 4;
                      final urgun = box.maxWidth / bagana;
                      return Wrap(children: [
                        for (final u in uilchilgee) SizedBox(width: urgun, child: _UilchilgeeTovch(u: u)),
                      ]);
                    }),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _tovchNer(String ner) {
    final k = ner.replaceAll('.', ' ').trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return ((k.isNotEmpty ? k[0][0] : '') + (k.length > 1 ? k[1][0] : '')).toUpperCase();
  }

  static String _bukhNer(AuthUser? u) {
    if (u == null) return '';
    return u.ovog.isNotEmpty ? '${u.ovog[0]}. ${u.ner}' : u.ner;
  }
}

class _Uilchilgee {
  const _Uilchilgee(this.icon, this.ner, this.gradient, this.onTap, {this.too = 0});
  final IconData icon;
  final String ner;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int too;
}

/// Апп-лаунчер маягийн дугуй булантай градиент дүрс + нэр
class _UilchilgeeTovch extends StatelessWidget {
  const _UilchilgeeTovch({required this.u});
  final _Uilchilgee u;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: u.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 2),
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: u.gradient),
                boxShadow: [
                  BoxShadow(color: u.gradient.last.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(u.icon, size: 25, color: Colors.white),
            ),
            if (u.too > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: c.cardBackground, width: 2),
                  ),
                  child: Text(u.too > 99 ? '99+' : '${u.too}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, color: Colors.white)),
                ),
              ),
          ]),
          const SizedBox(height: 7),
          Text(u.ner,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.primary)),
        ]),
      ),
    );
  }
}

/// Сарын ажилласан хувийн цагираг
class _KhuviTsagirag extends StatelessWidget {
  const _KhuviTsagirag({required this.khuvi, this.tailbar = 'ажилласан', this.unguud});
  final double khuvi;
  final String tailbar;
  final List<Color>? unguud;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: khuvi),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: 92,
        height: 92,
        child: CustomPaint(
          painter: _TsagiragZurag(v, (unguud?.last ?? _brand).withValues(alpha: 0.12), unguud),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(v * 100).round()}%',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: c.primary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              Text(tailbar, style: TextStyle(fontSize: 10.5, color: c.mutedForeground)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TsagiragZurag extends CustomPainter {
  _TsagiragZurag(this.khuvi, this.ar, [this.unguud]);
  final double khuvi;
  final Color ar;
  final List<Color>? unguud;
  @override
  void paint(Canvas canvas, Size size) {
    const zuzaan = 9.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(zuzaan / 2);
    canvas.drawArc(r, 0, 6.2832, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = zuzaan..color = ar);
    if (khuvi <= 0) return;
    canvas.drawArc(
      r,
      -1.5708,
      6.2832 * khuvi.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = zuzaan
        ..strokeCap = StrokeCap.round
        // Дээрээс эхэлж (анхдагч: алтлаг шаргал градиент)
        ..shader = SweepGradient(
          transform: const GradientRotation(-1.5708),
          colors: unguud ?? const [Color(0xFFF6B003), Color(0xFFF18F02), Color(0xFFE67E00), Color(0xFFF6B003)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TsagiragZurag o) => o.khuvi != khuvi || o.ar != ar;
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.ungu, required this.ner, required this.utga});
  final IconData icon;
  final Color ungu;
  final String ner, utga;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: ungu.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: ungu),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(ner, style: TextStyle(fontSize: 13, color: c.mutedForeground))),
        Text(utga,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: c.primary,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

class _AnkhaarPill extends StatelessWidget {
  const _AnkhaarPill({required this.icon, required this.text, required this.ungu, required this.onTap});
  final IconData icon;
  final String text;
  final Color ungu;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: ungu.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: ungu),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(fontSize: 13, color: ungu)),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 16, color: ungu),
          ]),
        ),
      ),
    );
  }
}

class _Toirog extends StatelessWidget {
  const _Toirog(this.d, this.alpha);
  final double d, alpha;
  @override
  Widget build(BuildContext context) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}


/// Өнөөдрийн ажлын самбар (Ажил менежмент) — "Энэ сарын ирц" карттай ижил хэв маяг.
/// Төлөвийн өнгө вэбтэй ижил: дууссан = ногоон, хийгдэж буй = цэнхэр, хэтэрсэн = улаан.
class _AjilKart extends StatelessWidget {
  const _AjilKart({required this.ajluud, required this.achaallaj, required this.onTap});
  final List<ApiTask>? ajluud;
  final bool achaallaj;
  final VoidCallback onTap;

  static const _nogoon = Color(0xFF16A34A);
  static const _tsenkher = Color(0xFF2563EB);
  static const _ulaan = Color(0xFFFC313F);

  static DateTime _udur(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _unuudur(ApiTask t, DateTime unuudur) {
    final ekh = t.ekhlekhOgnoo ?? t.ekhlekhTsag;
    final tug = t.duusakhOgnoo ?? t.duusakhTsag ?? ekh;
    if (ekh == null) return false;
    return !_udur(ekh.toLocal()).isAfter(unuudur) && !_udur((tug ?? ekh).toLocal()).isBefore(unuudur);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unuudur = _udur(DateTime.now());
    final bukh = ajluud ?? const <ApiTask>[];
    final unuudriin = bukh.where((t) => _unuudur(t, unuudur)).toList();
    bool duussan(ApiTask t) => t.tuluv == 'duussan' || t.tuluv == 'shalga';
    final duussanToo = unuudriin.where(duussan).length;
    final khiigdej = unuudriin.where((t) => t.tuluv == 'khiigdej bui').length;
    final khetersen = bukh.where((t) {
      if (duussan(t)) return false;
      final tug = t.khugatsaaDuusakhOgnoo ?? t.duusakhTsag;
      return tug != null && _udur(tug.toLocal()).isBefore(unuudur);
    }).length;
    final khuvi = unuudriin.isEmpty ? 0.0 : duussanToo / unuudriin.length;
    final ach = achaallaj || ajluud == null;

    return Material(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border),
            boxShadow: [BoxShadow(color: _brand.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Row(children: [
            _KhuviTsagirag(
              khuvi: ach ? 0 : khuvi,
              tailbar: 'дууссан',
              unguud: const [Color(0xFF4ADE80), _nogoon, Color(0xFF15803D), Color(0xFF4ADE80)],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Өнөөдрийн ажил', style: TextStyle(fontSize: 13, color: c.mutedForeground))),
                  Icon(Icons.chevron_right_rounded, size: 20, color: c.mutedForeground),
                ]),
                const SizedBox(height: 6),
                _MiniStat(
                  icon: Icons.checklist_rounded,
                  ungu: _brand,
                  ner: 'Өнөөдөр',
                  utga: ach ? '…' : '$duussanToo / ${unuudriin.length}',
                ),
                _MiniStat(
                  icon: Icons.play_circle_outline_rounded,
                  ungu: _tsenkher,
                  ner: 'Хийгдэж буй',
                  utga: ach ? '…' : '$khiigdej',
                ),
                _MiniStat(
                  icon: Icons.alarm_rounded,
                  ungu: khetersen == 0 ? _nogoon : _ulaan,
                  ner: 'Хэтэрсэн',
                  utga: ach ? '…' : (khetersen == 0 ? 'Байхгүй' : '$khetersen'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
