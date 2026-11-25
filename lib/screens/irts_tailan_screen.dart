import 'package:flutter/material.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';
import '../utils/irts_logic.dart';

const _brand = Color(0xFF315BB0);
const _tabular = [FontFeature.tabularFigures()];

String _hm(DateTime? d) =>
    d == null ? '—' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _md(DateTime d) => '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
const _garag = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];

/// Ирцийн тайлан: сарын ажилласан цаг хуваарьтай харьцуулсан, задаргаа, өдөр бүрээр.
class IrtsTailanScreen extends StatefulWidget {
  const IrtsTailanScreen({super.key});
  @override
  State<IrtsTailanScreen> createState() => _IrtsTailanScreenState();
}

class _IrtsTailanScreenState extends State<IrtsTailanScreen> {
  DateTime _sar = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic>? _barilga;
  List<Map<String, dynamic>> _irtsuud = [];
  bool _achaallaj = true;
  String? _aldaa;

  @override
  void initState() {
    super.initState();
    _achaallaya();
  }

  Future<void> _achaallaya() async {
    setState(() => _achaallaj = true);
    try {
      _barilga ??= await IrtsService.barilgaAvya();
      final list = await IrtsService.sarynIrts(_sar);
      if (!mounted) return;
      setState(() {
        _irtsuud = list;
        _aldaa = null;
        _achaallaj = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aldaa = e is IrtsAldaa ? e.message : 'Ирцийн сервертэй холбогдож чадсангүй.';
        _achaallaj = false;
      });
    }
  }

  void _sarSoliy(int n) {
    setState(() => _sar = DateTime(_sar.year, _sar.month + n));
    _achaallaya();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final odooginSar = _sar.year == now.year && _sar.month == now.month;
    final dun = sarynDunTootsoo(_irtsuud, _barilga, _sar);
    final tugsgul = DateTime(_sar.year, _sar.month + 1, 0);
    final udruud = [..._irtsuud]
      ..sort((a, b) => (b['ognoo'] ?? '').toString().compareTo((a['ognoo'] ?? '').toString()));

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: RefreshIndicator(
              color: _brand,
              onRefresh: _achaallaya,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _Tolgoi(garchig: 'Ирцийн тайлан'),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _DuguiTovch(icon: Icons.chevron_left_rounded, onTap: () => _sarSoliy(-1), tailbar: 'Өмнөх сар'),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${_md(_sar)} – ${_md(tugsgul)}',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular),
                          ),
                        ),
                      ),
                    ),
                    _DuguiTovch(
                      icon: Icons.chevron_right_rounded,
                      onTap: odooginSar ? null : () => _sarSoliy(1),
                      tailbar: 'Дараах сар',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (_aldaa != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_aldaa!, style: TextStyle(color: c.destructive, fontSize: 13)),
                    ),

                  // ── Ажилласан цаг ──
                  _Kart(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Ажилласан цаг', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                      const SizedBox(height: 4),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text.rich(TextSpan(children: [
                              TextSpan(
                                text: _achaallaj ? '…' : tsagMinutTekst(dun.ajillasan),
                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.8, color: c.primary),
                              ),
                              TextSpan(
                                text: '  / ${tsagMinutTekst(dun.khuvaart)}',
                                style: TextStyle(fontSize: 15, color: c.mutedForeground),
                              ),
                            ]), style: const TextStyle(fontFeatures: _tabular)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${(dun.khuvi * 100).round()}%',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.mutedForeground)),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _achaallaj ? null : dun.khuvi,
                          minHeight: 10,
                          backgroundColor: c.muted,
                          color: _brand,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Mur(tseg: _brand, ner: 'Хуваарьт цаг', utga: tsagMinutTekst(dun.khuvaart)),
                      _Mur(tseg: const Color(0xFF8B5CF6), ner: 'Илүү цаг', utga: tsagMinutTekst(dun.iluu)),
                      _Mur(tseg: c.border, ner: 'Үлдсэн', utga: tsagMinutTekst(dun.uldsen), suuliin: true),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── Ажиллаагүй цаг ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(children: [
                      Expanded(child: Text('Ажиллаагүй цаг', style: TextStyle(fontSize: 14, color: c.mutedForeground))),
                      Text(tsagMinutTekst(dun.khotsorson + dun.ertTarsan),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  _Kart(
                    child: Column(children: [
                      _Mur(ner: 'Хоцорсон', utga: tsagMinutTekst(dun.khotsorson), utgaUngu: dun.khotsorson > 0 ? const Color(0xFFD97706) : null),
                      _Mur(ner: 'Эрт тарсан', utga: tsagMinutTekst(dun.ertTarsan)),
                      _Mur(ner: 'Тасалсан', utga: '${dun.tasalsanUdur} өдөр', utgaUngu: dun.tasalsanUdur > 0 ? c.destructive : null),
                      _Mur(ner: 'Ирсэн өдөр', utga: '${dun.irsenUdur} / ${dun.ajlynUdur}', suuliin: true),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── Өдөр бүрээр ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('Өдөр бүрээр', style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                  ),
                  const SizedBox(height: 8),
                  _Kart(
                    padding: EdgeInsets.zero,
                    child: udruud.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_achaallaj ? 'Ачаалж байна…' : 'Энэ сард бүртгэл алга.',
                                style: TextStyle(color: c.mutedForeground)),
                          )
                        : Column(children: [
                            for (var i = 0; i < udruud.length; i++) _OdriinMur(x: udruud[i], suuliin: i == udruud.length - 1),
                          ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OdriinMur extends StatelessWidget {
  const _OdriinMur({required this.x, required this.suuliin});
  final Map x;
  final bool suuliin;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ognoo = ognooUnshikh(x['ognoo']) ?? DateTime.now();
    final tuluv = bichlegiinTuluv(x);
    final t = irtsTuluvuud[tuluv];
    final ajillasan = (x['ajillasanMinut'] as num?)?.round() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: suuliin ? null : Border(bottom: BorderSide(color: c.border))),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Column(children: [
            Text(_garag[ognoo.weekday - 1], style: TextStyle(fontSize: 11, color: c.mutedForeground)),
            Text('${ognoo.day}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_hm(ognooUnshikh(x['irsenTsag']))} – ${_hm(ognooUnshikh(x['yawsanTsag']))}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
            if (t != null)
              Row(children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: t.ungu, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(t.ner, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
              ]),
          ]),
        ),
        Text(ajillasan > 0 ? tsagMinutTekst(ajillasan) : '—',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.mutedForeground, fontFeatures: _tabular)),
      ]),
    );
  }
}

class _Tolgoi extends StatelessWidget {
  const _Tolgoi({required this.garchig});
  final String garchig;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 52,
      child: Stack(alignment: Alignment.center, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _DuguiTovch(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop(), tailbar: 'Буцах'),
        ),
        Text(garchig, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.primary)),
      ]),
    );
  }
}

class _DuguiTovch extends StatelessWidget {
  const _DuguiTovch({required this.icon, required this.onTap, required this.tailbar});
  final IconData icon;
  final VoidCallback? onTap;
  final String tailbar;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton(
      tooltip: tailbar,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: c.cardBackground,
        disabledBackgroundColor: c.muted,
        fixedSize: const Size(44, 44),
      ),
      icon: Icon(icon, color: onTap == null ? c.mutedForeground.withValues(alpha: 0.4) : c.primary),
    );
  }
}

class _Kart extends StatelessWidget {
  const _Kart({required this.child, this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 6)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: context.colors.cardBackground, borderRadius: BorderRadius.circular(22)),
      child: child,
    );
  }
}

class _Mur extends StatelessWidget {
  const _Mur({required this.ner, required this.utga, this.tseg, this.utgaUngu, this.suuliin = false});
  final String ner;
  final String utga;
  final Color? tseg;
  final Color? utgaUngu;
  final bool suuliin;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: suuliin ? null : Border(bottom: BorderSide(color: c.border))),
      child: Row(children: [
        if (tseg != null) ...[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: tseg, shape: BoxShape.circle)),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(ner, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary))),
        Text(utga,
            style: TextStyle(
              fontSize: 15,
              color: utgaUngu ?? c.mutedForeground,
              fontWeight: utgaUngu != null ? FontWeight.w500 : FontWeight.w500,
              fontFeatures: _tabular,
            )),
      ]),
    );
  }
}
