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

const _garagButen = ['Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба', 'Ням'];

enum _Khugatsaa { udur, doloo, sar }

const _khugatsaaNer = {
  _Khugatsaa.udur: 'Өдөр',
  _Khugatsaa.doloo: '7 хоног',
  _Khugatsaa.sar: 'Сар',
};

/// Ирцийн тайлан: Өдөр / 7 хоног / Сар сонгоод тухайн хугацааны хураангуй
/// (ажилласан цаг хуваарьтай харьцуулсан, хоцролт, илүү цаг...) ба өдрүүд.
class IrtsTailanScreen extends StatefulWidget {
  const IrtsTailanScreen({super.key});
  @override
  State<IrtsTailanScreen> createState() => _IrtsTailanScreenState();
}

class _IrtsTailanScreenState extends State<IrtsTailanScreen> {
  _Khugatsaa _turul = _Khugatsaa.sar;
  // Сонгосон хугацааг агуулсан аль нэг өдөр (өдөр/долоо хоног/сарын эхлэлийг үүнээс бодно)
  DateTime _songoson = _ognoo(DateTime.now());
  Map<String, dynamic>? _barilga;
  List<Map<String, dynamic>> _irtsuud = [];
  bool _achaallaj = true;
  String? _aldaa;
  int _khuselt = 0;

  static DateTime _ognoo(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [ekh, tug) — сонгосон хугацааны хил
  (DateTime, DateTime) get _khil {
    final d = _songoson;
    switch (_turul) {
      case _Khugatsaa.udur:
        return (d, DateTime(d.year, d.month, d.day + 1));
      case _Khugatsaa.doloo:
        final ekh = DateTime(d.year, d.month, d.day - (d.weekday - 1));
        return (ekh, DateTime(ekh.year, ekh.month, ekh.day + 7));
      case _Khugatsaa.sar:
        return (DateTime(d.year, d.month, 1), DateTime(d.year, d.month + 1, 1));
    }
  }

  @override
  void initState() {
    super.initState();
    _achaallaya();
  }

  Future<void> _achaallaya() async {
    final dugaar = ++_khuselt;
    setState(() => _achaallaj = true);
    try {
      _barilga ??= await IrtsService.barilgaAvya();
      final (ekh, tug) = _khil;
      final list = await IrtsService.khugatsaanyIrts(ekh, tug);
      // Хурдан солиход хуучин хариу шинийг дарахаас сэргийлнэ
      if (!mounted || dugaar != _khuselt) return;
      setState(() {
        _irtsuud = list;
        _aldaa = null;
        _achaallaj = false;
      });
    } catch (e) {
      if (!mounted || dugaar != _khuselt) return;
      setState(() {
        _aldaa = e is IrtsAldaa ? e.message : 'Ирцийн сервертэй холбогдож чадсангүй.';
        _achaallaj = false;
      });
    }
  }

  void _turulSoliy(_Khugatsaa t) {
    if (t == _turul) return;
    setState(() {
      _turul = t;
      _songoson = _ognoo(DateTime.now());
    });
    _achaallaya();
  }

  void _shiljikh(int n) {
    final d = _songoson;
    setState(() {
      _songoson = switch (_turul) {
        _Khugatsaa.udur => DateTime(d.year, d.month, d.day + n),
        _Khugatsaa.doloo => DateTime(d.year, d.month, d.day + 7 * n),
        _Khugatsaa.sar => DateTime(d.year, d.month + n, 1),
      };
    });
    _achaallaya();
  }

  String get _khugatsaaTekst {
    final (ekh, tug) = _khil;
    switch (_turul) {
      case _Khugatsaa.udur:
        return '${_md(ekh)}, ${_garagButen[ekh.weekday - 1]}';
      case _Khugatsaa.doloo:
        return '${_md(ekh)} – ${_md(tug.subtract(const Duration(days: 1)))}';
      case _Khugatsaa.sar:
        return '${ekh.year} оны ${ekh.month}-р сар';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (ekh, tug) = _khil;
    final odooginKhugatsaa = !tug.isBefore(_ognoo(DateTime.now()).add(const Duration(days: 1)));
    final dun = khugatsaanyDunTootsoo(_irtsuud, _barilga, ekh, tug);
    final udruud = [..._irtsuud]
      ..sort((a, b) => (b['ognoo'] ?? '').toString().compareTo((a['ognoo'] ?? '').toString()));
    String utga(int m) => _achaallaj ? '…' : tsagMinutTekst(m);

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

                  // ── Өдөр / 7 хоног / Сар ──
                  _Segment(utga: _turul, onChange: _turulSoliy),
                  const SizedBox(height: 12),
                  Row(children: [
                    _DuguiTovch(icon: Icons.chevron_left_rounded, onTap: () => _shiljikh(-1), tailbar: 'Өмнөх'),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_khugatsaaTekst,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
                      ),
                    ),
                    _DuguiTovch(
                      icon: Icons.chevron_right_rounded,
                      onTap: odooginKhugatsaa ? null : () => _shiljikh(1),
                      tailbar: 'Дараах',
                    ),
                  ]),
                  const SizedBox(height: 14),
                  if (_aldaa != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_aldaa!, style: TextStyle(color: c.destructive, fontSize: 13)),
                    ),

                  // ── Хураангуй: ажилласан цаг / хуваарьт ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4F7FE8), Color(0xFF315BB0), Color(0xFF3B2FA8)],
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Text('Ажилласан цаг', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                        const Spacer(),
                        Text(_achaallaj ? '' : '${(dun.khuvi * 100).round()}%',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontFeatures: _tabular)),
                      ]),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: utga(dun.ajillasan),
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.8, color: Colors.white),
                            ),
                            TextSpan(
                              text: '  / ${tsagMinutTekst(dun.khuvaart)}',
                              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ]),
                          style: const TextStyle(fontFeatures: _tabular),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _achaallaj ? null : dun.khuvi,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _achaallaj ? ' ' : 'Үлдсэн ${tsagMinutTekst(dun.uldsen)} · Ирсэн ${dun.irsenUdur} / ${dun.ajlynUdur} өдөр',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75), fontFeatures: _tabular),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  // ── Үзүүлэлтүүд ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: [
                      _Khavtan(ner: 'Хоцорсон', utga: utga(dun.khotsorson), ungu: const Color(0xFFF59E0B)),
                      _Khavtan(ner: 'Илүү цаг', utga: utga(dun.iluu), ungu: const Color(0xFF8B5CF6)),
                      _Khavtan(ner: 'Эрт тарсан', utga: utga(dun.ertTarsan), ungu: const Color(0xFF0EA5E9)),
                      _Khavtan(
                        ner: 'Тасалсан',
                        utga: _achaallaj ? '…' : '${dun.tasalsanUdur} өдөр',
                        ungu: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Өдрүүд ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(_turul == _Khugatsaa.udur ? 'Бүртгэл' : 'Өдрүүд',
                        style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                  ),
                  const SizedBox(height: 8),
                  _Kart(
                    padding: EdgeInsets.zero,
                    child: udruud.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_achaallaj ? 'Ачаалж байна…' : 'Энэ хугацаанд бүртгэл алга.',
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

/// Өдөр / 7 хоног / Сар сонголт
class _Segment extends StatelessWidget {
  const _Segment({required this.utga, required this.onChange});
  final _Khugatsaa utga;
  final ValueChanged<_Khugatsaa> onChange;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.cardBackground, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        for (final t in _Khugatsaa.values)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChange(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t == utga ? _brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _khugatsaaNer[t]!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t == utga ? Colors.white : c.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Өнгөт жижиг үзүүлэлтийн хавтан
class _Khavtan extends StatelessWidget {
  const _Khavtan({required this.ner, required this.utga, required this.ungu});
  final String ner;
  final String utga;
  final Color ungu;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(ungu.withValues(alpha: 0.12), c.cardBackground),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ungu.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: ungu, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(child: Text(ner, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.mutedForeground))),
        ]),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(utga, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ungu, fontFeatures: _tabular)),
        ),
      ]),
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
