import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';
import '../utils/irts_logic.dart';
import 'irts_tailan_screen.dart';
import 'khuselt_ilgeekh_screen.dart';
import 'profail_tses_screen.dart';
import '../widgets/irts_gazriin_zurag.dart';
import '../widgets/medegdel_khonkh.dart';

const _tabular = [FontFeature.tabularFigures()];
const _brand = Color(0xFF315BB0);
const _gunTeal = Color(0xFF183B83);
const _garag = ['Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба', 'Ням'];
const _garagTovch = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];

String _hm(DateTime? d) =>
    d == null ? '--:--' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _md(DateTime d) => '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
String _ymd(DateTime d) => '${d.year}.${_md(d)}';

/// Ирц: дээр нь том бүртгэлийн товч, доор нь чирэгддэг самбар
/// (Цаг бүртгэл: өнөөдөр + энэ долоо хоног; Хүсэлт: миний хүсэлтүүд).
class IrtsScreen extends StatefulWidget {
  const IrtsScreen({super.key, this.onLogout});
  /// irts хэрэглэгчид өөр таб байхгүй тул гарах товч энд харагдана
  final VoidCallback? onLogout;
  @override
  State<IrtsScreen> createState() => _IrtsScreenState();
}

class _IrtsScreenState extends State<IrtsScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _barilga;
  Map<String, dynamic>? _unuudur;
  List<Map<String, dynamic>> _doloo = [];
  List<Map<String, dynamic>> _khuseltuud = [];
  DateTime _odoo = DateTime.now();
  bool _achaallaj = true;
  bool _burtgej = false;
  String? _aldaa;
  int _tab = 0; // 0 = цаг бүртгэл, 1 = хүсэлт
  Timer? _tsag;
  late final AnimationController _impuls =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  DateTime get _doloonEkh {
    final d = DateTime(_odoo.year, _odoo.month, _odoo.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _achaallaya();
    _tsag = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _odoo = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tsag?.cancel();
    _impuls.dispose();
    super.dispose();
  }

  Future<void> _achaallaya() async {
    try {
      // Барилгыг эхэлж тодорхойлно (барилга оноогоогүй Admin бол байгууллагын эхнийх)
      final barilga = await IrtsService.barilgaAvya();
      if (IrtsService.barilgiinId == null) {
        if (!mounted) return;
        setState(() {
          _achaallaj = false;
          _aldaa = 'Байгууллагад барилга бүртгэгдээгүй байна. Удирдлагадаа хандана уу.';
        });
        return;
      }
      final ekh = _doloonEkh;
      final res = await Future.wait([
        IrtsService.unuudriinIrts(),
        IrtsService.khugatsaanyIrts(ekh, ekh.add(const Duration(days: 7))),
        IrtsService.miniiKhuseltuud(),
      ]);
      if (!mounted) return;
      setState(() {
        _barilga = barilga;
        _unuudur = res[0] as Map<String, dynamic>?;
        _doloo = res[1] as List<Map<String, dynamic>>;
        _khuseltuud = res[2] as List<Map<String, dynamic>>;
        _aldaa = null;
        _achaallaj = false;
        _odoo = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _achaallaj = false;
        _aldaa = e is IrtsAldaa ? e.message : 'Ирцийн сервертэй холбогдож чадсангүй. Интернэтээ шалгаад дахин оролдоно уу.';
      });
    }
  }

  Future<void> _burtguulye(IrtsUildel uildel) async {
    final turul = uildel.turul;
    if (turul == null || _burtgej) return;
    setState(() => _burtgej = true);
    try {
      await IrtsService.burtguulye(turul);
      await _achaallaya();
      if (mounted) _medegdel('${uildel.burtgesen}, ${_hm(DateTime.now())}');
    } catch (e) {
      if (mounted) _medegdel(e.toString(), aldaa: true);
    } finally {
      if (mounted) setState(() => _burtgej = false);
    }
  }

  void _medegdel(String text, {bool aldaa = false}) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      backgroundColor: aldaa ? c.destructive : c.primary,
    ));
  }

  Future<void> _khuseltIlgeekh() async {
    final turul = await khuseltTurulSongokh(context);
    if (turul == null || !mounted) return;
    final ilgeesen = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => KhuseltIlgeekhScreen(turul: turul)),
    );
    if (ilgeesen == true) {
      _medegdel('Хүсэлт илгээгдлээ');
      setState(() => _tab = 1);
      _achaallaya();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (MediaQuery.of(context).disableAnimations) {
      _impuls.stop();
    } else if (!_impuls.isAnimating) {
      _impuls.repeat();
    }
    if (_achaallaj) {
      return Scaffold(
        backgroundColor: c.loginBackground,
        body: const Center(child: CircularProgressIndicator(color: _brand)),
      );
    }
    final uildel = irtsiinUildel(irts: _unuudur, barilga: _barilga, odoo: _odoo);
    Widget deed(double doodZai) => _DeedKhesek(
      doodZai: doodZai,
      odoo: _odoo,
      barilga: _barilga,
      uildel: uildel,
      burtgej: _burtgej,
      impuls: _impuls,
      onTap: () => _burtguulye(uildel),
      onLogout: widget.onLogout,
      aldaa: _aldaa,
      onDakhin: _achaallaya,
    );
    Widget samba(ScrollController? sc) => _Samba(
          scroll: sc,
          tab: _tab,
          onTab: (i) => setState(() => _tab = i),
          odoo: _odoo,
          barilga: _barilga,
          irts: _unuudur,
          doloo: _doloo,
          doloonEkh: _doloonEkh,
          khuseltuud: _khuseltuud,
          onKhuselt: _khuseltIlgeekh,
          onRefresh: _achaallaya,
        );

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: LayoutBuilder(builder: (context, box) {
        // iPad, Fold дэлгэсэн, хэвтээ утас: зүүн талд товч, баруун талд самбар
        if (box.maxWidth >= 720 || box.maxWidth > box.maxHeight * 1.3) {
          return Row(children: [
            Expanded(flex: 5, child: deed(0)),
            Expanded(
              flex: 6,
              child: SafeArea(
                left: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  decoration: BoxDecoration(color: c.cardBackground, borderRadius: BorderRadius.circular(28)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(28), child: samba(null)),
                ),
              ),
            ),
          ]);
        }
        // Timely шиг: газрын зураг бүтэн дэлгэц, самбар доор хураагдсан
        // (табууд + "Өнөөдөр" л харагдана), дээш чирэхэд дэлгэрнэ.
        const kharagdakh = 156.0;
        final ekhKhemjee = (kharagdakh / box.maxHeight).clamp(0.12, 0.5);
        return Stack(children: [
          Positioned.fill(child: deed(kharagdakh - 28)),
          DraggableScrollableSheet(
            initialChildSize: ekhKhemjee,
            minChildSize: ekhKhemjee,
            maxChildSize: 0.92,
            snap: true,
            builder: (context, sc) => Container(
              decoration: BoxDecoration(
                color: c.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
              ),
              child: samba(sc),
            ),
          ),
        ]);
      }),
    );
  }
}

/// Дээд хэсэг: барилга, цаг, том дугуй бүртгэлийн товч
class _DeedKhesek extends StatelessWidget {
  const _DeedKhesek({
    required this.odoo,
    required this.barilga,
    required this.uildel,
    required this.burtgej,
    required this.impuls,
    required this.onTap,
    required this.onDakhin,
    this.doodZai = 0,
    this.onLogout,
    this.aldaa,
  });
  final DateTime odoo;
  final Map? barilga;
  final IrtsUildel uildel;
  final bool burtgej;
  final Animation<double> impuls;
  final VoidCallback onTap;
  final VoidCallback onDakhin;
  /// Доод самбарын харагдах өндөр — товч, газрын зургийн товчнууд түүний дээр байрлана
  final double doodZai;
  final VoidCallback? onLogout;
  final String? aldaa;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final idevkhtei = uildel.turul != null && !burtgej;
    final orokh = uildel == IrtsUildel.orokh || uildel == IrtsUildel.chuluunaasOrokh || uildel == IrtsUildel.tsainiiOrokh;
    final ungu = idevkhtei ? (orokh ? _brand : _gunTeal) : const Color(0xFFB8C2CC);
    final ikon = switch (uildel) {
      IrtsUildel.orokh || IrtsUildel.chuluunaasOrokh => Icons.login_rounded,
      IrtsUildel.tsainiiGarakh => Icons.coffee_rounded,
      IrtsUildel.tsainiiOrokh => Icons.work_outline_rounded,
      IrtsUildel.garakh || IrtsUildel.garakhHulee => Icons.logout_rounded,
      IrtsUildel.amralt => Icons.beach_access_rounded,
      _ => Icons.check_rounded,
    };
    final tailbar = switch (uildel) {
      IrtsUildel.garakhHulee => 'Цайны дараа хэсэг хугацаанд гарах боломжгүй',
      _ => null,
    };
    final tovchNer = switch (uildel) {
      IrtsUildel.duussan => 'Дууссан',
      IrtsUildel.amralt => 'Амралт',
      _ => uildel.tovch,
    };

    // Арын давхарга: OpenStreetMap газрын зураг (миний байршил, оффисын бүс)
    return Stack(children: [
      Positioned.fill(child: IrtsGazriinZurag(doodZai: doodZai + 36)),
      SafeArea(
        bottom: false,
        right: false,
        child: LayoutBuilder(builder: (context, box) {
          final r = (math.min(box.maxHeight, box.maxWidth) * 0.17).clamp(46.0, 80.0);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                if (onLogout != null) ...[
                  IconButton(
                    tooltip: 'Профайл',
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProfailTsesScreen(onLogout: onLogout!, irtsKharagdakh: true),
                    )),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    icon: const Icon(Icons.person_outline_rounded, size: 22, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.location_on_rounded, size: 17, color: _brand),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          barilga?['ner']?.toString() ?? 'Барилга',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                const MedegdelKhonkh(),
              ]),
            ),
            if (aldaa != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Material(
                  color: c.destructive.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                    child: Row(children: [
                      Expanded(child: Text(aldaa!, style: TextStyle(fontSize: 13, color: c.destructive))),
                      TextButton(onPressed: onDakhin, child: const Text('Дахин ачаалах')),
                    ]),
                  ),
                ),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Том дугуй товч + импульс
                    Semantics(
                      button: true,
                      enabled: idevkhtei,
                      label: tovchNer,
                      child: GestureDetector(
                        onTap: idevkhtei ? onTap : null,
                        child: SizedBox(
                          width: r * 2.5,
                          height: r * 2.5,
                          child: AnimatedBuilder(
                            animation: impuls,
                            builder: (_, __) => Stack(alignment: Alignment.center, children: [
                              if (idevkhtei)
                                for (final k in [0.0, 0.5])
                                  Builder(builder: (_) {
                                    final q = (impuls.value + k) % 1;
                                    return Container(
                                      width: r * 2 * (1 + q * 0.25),
                                      height: r * 2 * (1 + q * 0.25),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: ungu.withValues(alpha: 0.18 * (1 - q)),
                                      ),
                                    );
                                  }),
                              Container(
                                width: r * 2,
                                height: r * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ungu,
                                  boxShadow: [
                                    BoxShadow(
                                      color: ungu.withValues(alpha: idevkhtei ? 0.35 : 0.1),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: burtgej
                                    ? const Center(
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                                        ),
                                      )
                                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(ikon, color: Colors.white, size: r * 0.42),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(tovchNer,
                                                style: TextStyle(fontSize: r * 0.22, fontWeight: FontWeight.w500, color: Colors.white)),
                                          ),
                                        ),
                                      ]),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                    if (tailbar != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                        child: Text(tailbar, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                      ),
                  ]),
                ),
              ),
            ),
            SizedBox(height: doodZai + 36),
          ]);
        }),
      ),
    ]);
  }
}

/// Доод самбар: Цаг бүртгэл / Хүсэлт
class _Samba extends StatelessWidget {
  const _Samba({
    required this.scroll,
    required this.tab,
    required this.onTab,
    required this.odoo,
    required this.barilga,
    required this.irts,
    required this.doloo,
    required this.doloonEkh,
    required this.khuseltuud,
    required this.onKhuselt,
    required this.onRefresh,
  });
  final ScrollController? scroll;
  final int tab;
  final ValueChanged<int> onTab;
  final DateTime odoo;
  final Map? barilga;
  final Map? irts;
  final List<Map<String, dynamic>> doloo;
  final DateTime doloonEkh;
  final List<Map<String, dynamic>> khuseltuud;
  final VoidCallback onKhuselt;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final khuleegdej = khuseltuud.where((h) => h['tuluv'] == 'huvlaj_baina').length;
    return Column(children: [
      Expanded(
        child: RefreshIndicator(
          color: _brand,
          onRefresh: onRefresh,
          child: ListView(
            controller: scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            children: [
              if (scroll != null)
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              Row(children: [
                _TomTab(ner: 'Цаг бүртгэл', icon: Icons.calendar_month_rounded, songogdson: tab == 0, onTap: () => onTab(0)),
                const SizedBox(width: 10),
                _TomTab(ner: 'Хүсэлт', icon: Icons.send_rounded, songogdson: tab == 1, too: khuleegdej, onTap: () => onTab(1)),
              ]),
              const SizedBox(height: 20),
              if (tab == 0) ..._tsagBurtgel(context, c) else ..._khuselt(c),
            ],
          ),
        ),
      ),
      if (tab == 1)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onKhuselt,
              style: FilledButton.styleFrom(backgroundColor: _brand, shape: const StadiumBorder()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Хүсэлт илгээх', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
    ]);
  }

  List<Widget> _tsagBurtgel(BuildContext context, AppColorScheme c) {
    final kh = odriinKhuvaari(barilga, odoo);
    final irsen = ognooUnshikh(irts?['irsenTsag']);
    final yawsan = ognooUnshikh(irts?['yawsanTsag']);
    var ajillasan = (irts?['ajillasanMinut'] as num?)?.round() ?? 0;
    if (ajillasan == 0 && irsen != null) ajillasan = (yawsan ?? odoo).difference(irsen).inMinutes.clamp(0, 24 * 60);
    final tuluv = bichlegiinTuluv(irts);
    final doloonMap = {
      for (final x in doloo)
        if (ognooUnshikh(x['ognoo']) != null) _md(ognooUnshikh(x['ognoo'])!): x,
    };
    return [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('Өнөөдөр', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: c.primary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_ymd(odoo)} (${_garagTovch[odoo.weekday - 1]})  ${kh == null ? 'Хуваарьгүй' : '${kh['neekhTsag']}–${kh['khaakhTsag']}'}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, color: c.mutedForeground, fontFeatures: _tabular),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      _UtgaMur(ner: 'Ирсэн цаг', utga: _hm(irsen)),
      _UtgaMur(ner: 'Явсан цаг', utga: _hm(yawsan)),
      _UtgaMur(ner: 'Ажилласан цаг', utga: tsagMinutTekst(ajillasan)),
      if (tuluv != null) _UtgaMur(ner: 'Төлөв', utga: irtsTuluvuud[tuluv]!.ner, ungu: irtsTuluvuud[tuluv]!.ungu),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(
          child: Text('Энэ долоо хоногийн ирц', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.primary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IrtsTailanScreen())),
          style: TextButton.styleFrom(foregroundColor: _brand, padding: const EdgeInsets.symmetric(horizontal: 6)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Дэлгэрэнгүй', style: TextStyle(fontWeight: FontWeight.w500)),
            Icon(Icons.chevron_right_rounded, size: 20),
          ]),
        ),
      ]),
      Text('${_ymd(doloonEkh)} - ${_ymd(doloonEkh.add(const Duration(days: 6)))}',
          style: TextStyle(fontSize: 13.5, color: c.mutedForeground, fontFeatures: _tabular)),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            color: _brand.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: _DolooMur(
              udur: Text('Өдөр', style: _gTolgoi(c)),
              irsen: Text('Ирсэн', style: _gTolgoi(c)),
              yawsan: Text('Явсан', style: _gTolgoi(c)),
              aj: Text('А/цаг', style: _gTolgoi(c)),
              tuluv: Text('Төлөв', style: _gTolgoi(c), textAlign: TextAlign.center),
            ),
          ),
          for (var i = 0; i < 7; i++) _dolooMur(c, doloonEkh.add(Duration(days: i)), doloonMap),
        ]),
      ),
    ];
  }

  Widget _dolooMur(AppColorScheme c, DateTime d, Map<String, Map<String, dynamic>> doloonMap) {
    final x = doloonMap[_md(d)];
    final ajlyn = odriinKhuvaari(barilga, d) != null;
    final ireedui = d.isAfter(odoo);
    final t = bichlegiinTuluv(x);
    final (tuluvNer, tuluvUngu) = t != null
        ? (irtsTuluvuud[t]!.ner, irtsTuluvuud[t]!.ungu)
        : !ajlyn
            ? ('Амралт', const Color(0xFF94A3B8))
            : ireedui
                ? ('—', const Color(0xFF94A3B8))
                : ('Ирээгүй', const Color(0xFFF43F5E));
    final aj = (x?['ajillasanMinut'] as num?)?.round() ?? 0;
    final unuudur = _md(d) == _md(odoo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: unuudur ? _brand.withValues(alpha: 0.05) : null,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: _DolooMur(
        udur: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_md(d), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
          Text(_garag[d.weekday - 1], style: TextStyle(fontSize: 11.5, color: c.mutedForeground)),
        ]),
        irsen: Text(_hm(ognooUnshikh(x?['irsenTsag'])), style: _gUtga(c)),
        yawsan: Text(_hm(ognooUnshikh(x?['yawsanTsag'])), style: _gUtga(c)),
        aj: Text(aj > 0 ? tsagMinutTekst(aj) : '--', style: _gUtga(c)),
        tuluv: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(color: tuluvUngu.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(tuluvNer,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: tuluvUngu)),
        ),
      ),
    );
  }

  List<Widget> _khuselt(AppColorScheme c) {
    if (khuseltuud.isEmpty) {
      return [
        const SizedBox(height: 30),
        Icon(Icons.inbox_outlined, size: 64, color: c.mutedForeground.withValues(alpha: 0.4)),
        const SizedBox(height: 10),
        Text('Хүсэлт алга', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.primary)),
        const SizedBox(height: 4),
        Text('Чөлөө, амралт авах бол доорх товчоор хүсэлт илгээнэ үү.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: c.mutedForeground)),
      ];
    }
    return [for (final h in khuseltuud) _KhuseltMur(h: h)];
  }
}

TextStyle _gTolgoi(AppColorScheme c) => TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.primary);
TextStyle _gUtga(AppColorScheme c) => TextStyle(fontSize: 13.5, color: c.primary, fontFeatures: _tabular);

class _DolooMur extends StatelessWidget {
  const _DolooMur({required this.udur, required this.irsen, required this.yawsan, required this.aj, required this.tuluv});
  final Widget udur, irsen, yawsan, aj, tuluv;
  @override
  Widget build(BuildContext context) {
    Widget fit(Widget w) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: w);
    return Row(children: [
      Expanded(flex: 5, child: udur),
      Expanded(flex: 4, child: fit(irsen)),
      Expanded(flex: 4, child: fit(yawsan)),
      Expanded(flex: 4, child: fit(aj)),
      Expanded(flex: 6, child: tuluv),
    ]);
  }
}

class _UtgaMur extends StatelessWidget {
  const _UtgaMur({required this.ner, required this.utga, this.ungu});
  final String ner, utga;
  final Color? ungu;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: Text(ner, style: TextStyle(fontSize: 16, color: c.mutedForeground))),
        Text(utga, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ungu ?? c.primary, fontFeatures: _tabular)),
      ]),
    );
  }
}

class _TomTab extends StatelessWidget {
  const _TomTab({required this.ner, required this.icon, required this.songogdson, required this.onTap, this.too = 0});
  final String ner;
  final IconData icon;
  final bool songogdson;
  final VoidCallback onTap;
  final int too;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: songogdson,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              color: songogdson ? _brand : _brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 21, color: songogdson ? Colors.white : _brand),
              const SizedBox(width: 8),
              Flexible(
                child: Text(ner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: songogdson ? Colors.white : _brand)),
              ),
              if (too > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(99)),
                  child: Text('$too', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

const _khuseltTuluv = {
  'huvlaj_baina': ('Хүлээгдэж буй', Color(0xFFD97706)),
  'zuvshurulusen': ('Зөвшөөрсөн', Color(0xFF059669)),
  'tatgalzsan': ('Татгалзсан', Color(0xFFDC2626)),
};

class _KhuseltMur extends StatelessWidget {
  const _KhuseltMur({required this.h});
  final Map h;

  String get _ner {
    if (h['turulKhuselt'] == 'chuluu') return 'Чөлөө';
    return h['turul'] == 'uvchiin' ? 'Өвчтэй' : 'Ээлжийн амралт';
  }

  String get _khugatsaa {
    if (h['turulKhuselt'] == 'chuluu') {
      final a = ognooUnshikh(h['ognoo']);
      final b = ognooUnshikh(h['duusakhOgnoo']);
      if (a == null) return '';
      final udur = b != null && _md(a) != _md(b) ? '${_md(a)}–${_md(b)}' : _md(a);
      return '$udur, ${h['ekhlekhTsag'] ?? ''}–${h['duusakhTsag'] ?? ''}';
    }
    final a = ognooUnshikh(h['ekhlekhOgnoo']);
    final b = ognooUnshikh(h['duusakhOgnoo']);
    if (a == null || b == null) return '';
    return '${_md(a)}–${_md(b)}, ${b.difference(a).inDays + 1} хоног';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (ner, ungu) = _khuseltTuluv[h['tuluv']] ?? ('—', c.mutedForeground);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(_ner, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: c.primary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: ungu.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
            child: Text(ner, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ungu)),
          ),
        ]),
        const SizedBox(height: 3),
        Text(_khugatsaa, style: TextStyle(fontSize: 13.5, color: c.mutedForeground, fontFeatures: _tabular)),
        if ((h['tailbar'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(h['tailbar'].toString(), style: TextStyle(fontSize: 14, color: c.primary)),
        ],
        if (h['tuluv'] == 'tatgalzsan' && (h['tatgalzsanShaltgaan'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Шалтгаан: ${h['tatgalzsanShaltgaan']}', style: TextStyle(fontSize: 13, color: ungu)),
        ],
      ]),
    );
  }
}
