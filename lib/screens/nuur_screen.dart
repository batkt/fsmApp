import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/irts_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../utils/irts_logic.dart';
import '../widgets/medegdel_khonkh.dart';
import 'irts_tailan_screen.dart';
import 'profail_tses_screen.dart';

const _brand = Color(0xFF315BB0);

/// Нүүр хуудас: мэндчилгээ, сарын модулиудын товч мэдээлэл.
class NuurScreen extends StatefulWidget {
  const NuurScreen({
    super.key,
    required this.irtsKharagdakh,
    required this.daalgavarKharagdakh,
    required this.onModulNeey,
    this.tsalinKharagdakh = false,
    this.onLogout,
  });

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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = AuthService.currentUser;
    final now = DateTime.now();
    final dun = sarynDunTootsoo(_sarynIrts, _barilga, DateTime(now.year, now.month));

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: RefreshIndicator(
        color: _brand,
        onRefresh: _achaallaya,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ── Цэнхэр толгой: мэндчилгээ ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_brand, Color(0xFF183B83)],
                ),
              ),
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12, bottom: 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    // Аватар дээр дарахад профайлын цэс
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
                        child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      child: Text(
                        _tovchNer(user?.ner ?? ''),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
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
                ),
              ]),
            ),

            // ── Энэ сард ──
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: BoxDecoration(
                  color: c.loginBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('Энэ сард',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.primary)),
                  ),
                  LayoutBuilder(builder: (context, box) {
                    final bagana = box.maxWidth >= 640 ? 4 : 2;
                    final tiles = <Widget>[
                      if (widget.irtsKharagdakh)
                        _ModulKart(
                          icon: Icons.schedule_rounded,
                          ungu: _brand,
                          ner: 'Цаг бүртгэл',
                          utga: _achaallaj ? '…' : tsagMinutTekst(dun.ajillasan),
                          utgaUngu: _brand,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const IrtsTailanScreen()),
                          ),
                        ),
                      if (widget.irtsKharagdakh)
                        _ModulKart(
                          icon: Icons.send_rounded,
                          ungu: const Color(0xFFF59E0B),
                          ner: 'Цагийн хүсэлт',
                          utga: _khuleegdejBui == null ? '—' : '$_khuleegdejBui хүлээгдэж буй',
                          utgaUngu: (_khuleegdejBui ?? 0) > 0 ? const Color(0xFFD97706) : c.mutedForeground,
                          onTap: () => widget.onModulNeey('Ирц'),
                        ),
                      if (widget.daalgavarKharagdakh)
                        _ModulKart(
                          icon: Icons.checklist_rounded,
                          ungu: const Color(0xFF2563EB),
                          ner: 'Даалгавар',
                          utga: _idevkhteiDaalgavar == null ? '—' : '$_idevkhteiDaalgavar идэвхтэй',
                          utgaUngu: const Color(0xFF2563EB),
                          onTap: () => widget.onModulNeey('Даалгавар'),
                        ),
                      if (widget.irtsKharagdakh)
                        _ModulKart(
                          icon: Icons.warning_amber_rounded,
                          ungu: const Color(0xFFDC2626),
                          ner: 'Хоцролт',
                          utga: _achaallaj
                              ? '…'
                              : dun.khotsorson == 0
                                  ? 'Хоцролтгүй'
                                  : tsagMinutTekst(dun.khotsorson),
                          utgaUngu: dun.khotsorson == 0 ? _brand : const Color(0xFFDC2626),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const IrtsTailanScreen()),
                          ),
                        ),
                      if (widget.tsalinKharagdakh)
                        _ModulKart(
                          icon: Icons.account_balance_wallet_outlined,
                          ungu: const Color(0xFF7C3AED),
                          ner: 'Цалин',
                          utga: 'Цалингийн задаргаа',
                          utgaUngu: const Color(0xFF7C3AED),
                          onTap: () => widget.onModulNeey('Цалин'),
                        ),
                    ];
                    const zai = 12.0;
                    final urgun = (box.maxWidth - zai * (bagana - 1)) / bagana;
                    return Wrap(
                      spacing: zai,
                      runSpacing: zai,
                      children: [for (final t in tiles) SizedBox(width: urgun, child: t)],
                    );
                  }),
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

/// "Энэ сард" хэсгийн модулийн карт
class _ModulKart extends StatelessWidget {
  const _ModulKart({
    required this.icon,
    required this.ungu,
    required this.ner,
    required this.utga,
    this.utgaUngu,
    this.onTap,
    this.idevkhgui = false,
  });
  final IconData icon;
  final Color ungu;
  final String ner;
  final String utga;
  final Color? utgaUngu;
  final VoidCallback? onTap;
  final bool idevkhgui;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: idevkhgui ? 0.6 : 1,
      child: Material(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: idevkhgui ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: ungu.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                  child: Icon(icon, size: 20, color: ungu),
                ),
                const Spacer(),
                if (!idevkhgui) Icon(Icons.chevron_right_rounded, color: c.mutedForeground.withValues(alpha: 0.6)),
              ]),
              const SizedBox(height: 18),
              Text(ner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary)),
              const SizedBox(height: 2),
              Text(utga,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: utgaUngu ?? c.mutedForeground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}
