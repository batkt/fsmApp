import 'package:flutter/material.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';
import '../utils/irts_logic.dart';

const _brand = Color(0xFF315BB0);
const _garag = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];

/// Ажлын хуваарь: сарын өдөр бүрийн ажлын цаг, амралтын өдөр, чөлөө/амралт.
class AjlynKhuvaariScreen extends StatefulWidget {
  const AjlynKhuvaariScreen({super.key});
  @override
  State<AjlynKhuvaariScreen> createState() => _AjlynKhuvaariScreenState();
}

class _AjlynKhuvaariScreenState extends State<AjlynKhuvaariScreen> {
  DateTime _sar = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic>? _barilga;
  Map<int, Map> _udrer = {};
  bool _achaallaj = true;
  final _unuudriinTulkhuur = GlobalKey();

  @override
  void initState() {
    super.initState();
    _achaallaya(unuudurRuu: true);
  }

  Future<void> _achaallaya({bool unuudurRuu = false}) async {
    setState(() => _achaallaj = true);
    try {
      _barilga ??= await IrtsService.barilgaAvya();
      final list = await IrtsService.sarynIrts(_sar);
      _udrer = {
        for (final x in list)
          if (ognooUnshikh(x['ognoo']) != null) ognooUnshikh(x['ognoo'])!.day: x,
      };
    } catch (_) {
      _udrer = {};
    }
    if (!mounted) return;
    setState(() => _achaallaj = false);
    if (unuudurRuu) _unuudurRuuGuilgekh();
  }

  void _unuudurRuuGuilgekh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _unuudriinTulkhuur.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.15, duration: const Duration(milliseconds: 350));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final odooginSar = _sar.year == now.year && _sar.month == now.month;
    final udriinToo = DateTime(_sar.year, _sar.month + 1, 0).day;

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      height: 52,
                      child: Stack(alignment: Alignment.center, children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Буцах',
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: IconButton.styleFrom(backgroundColor: c.cardBackground, fixedSize: const Size(44, 44)),
                            icon: Icon(Icons.arrow_back_rounded, color: c.primary),
                          ),
                        ),
                        Text('Ажлын хуваарь', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.primary)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      IconButton(
                        tooltip: 'Өмнөх сар',
                        onPressed: () {
                          setState(() => _sar = DateTime(_sar.year, _sar.month - 1));
                          _achaallaya();
                        },
                        icon: Icon(Icons.chevron_left_rounded, color: c.primary),
                      ),
                      Expanded(
                        child: Text('${_sar.month} сар ${_sar.year}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.4, color: c.primary)),
                      ),
                      if (!odooginSar)
                        IconButton(
                          tooltip: 'Дараах сар',
                          onPressed: () {
                            setState(() => _sar = DateTime(_sar.year, _sar.month + 1));
                            _achaallaya();
                          },
                          icon: Icon(Icons.chevron_right_rounded, color: c.primary),
                        ),
                      FilledButton.tonal(
                        onPressed: () {
                          if (odooginSar) return _unuudurRuuGuilgekh();
                          setState(() => _sar = DateTime(now.year, now.month));
                          _achaallaya(unuudurRuu: true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: c.cardBackground,
                          foregroundColor: c.primary,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Өнөөдөр', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
              if (_achaallaj && _barilga == null)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _brand)))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList.builder(
                    itemCount: udriinToo,
                    itemBuilder: (_, i) {
                      final udur = DateTime(_sar.year, _sar.month, i + 1);
                      final unuudur = odooginSar && udur.day == now.day;
                      return _OdriinMur(
                        key: unuudur ? _unuudriinTulkhuur : null,
                        udur: udur,
                        khuvaari: odriinKhuvaari(_barilga, udur),
                        irts: _udrer[udur.day],
                        unuudur: unuudur,
                      );
                    },
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OdriinMur extends StatelessWidget {
  const _OdriinMur({super.key, required this.udur, required this.khuvaari, required this.irts, required this.unuudur});
  final DateTime udur;
  final Map? khuvaari;
  final Map? irts;
  final bool unuudur;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tuluv = bichlegiinTuluv(irts);
    final chuluuAmralt = tuluv == 'amralt' || tuluv == 'chuluu';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 48,
          child: Column(children: [
            Text(_garag[udur.weekday - 1], style: TextStyle(fontSize: 12, color: c.mutedForeground)),
            const SizedBox(height: 2),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: unuudur ? const BoxDecoration(color: _brand, shape: BoxShape.circle) : null,
              child: Text('${udur.day}',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: unuudur ? Colors.white : c.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: khuvaari == null
              ? Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text('Амралтын өдөр',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.mutedForeground.withValues(alpha: 0.6))),
                )
              : Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(left: BorderSide(color: chuluuAmralt ? irtsTuluvuud[tuluv]!.ungu : _brand, width: 4)),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${khuvaari!['neekhTsag']} – ${khuvaari!['khaakhTsag']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: c.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            )),
                        Text(chuluuAmralt ? irtsTuluvuud[tuluv]!.ner : 'Ажиллах',
                            style: TextStyle(fontSize: 12.5, color: c.mutedForeground)),
                      ]),
                    ),
                    if (tuluv != null && !chuluuAmralt)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: irtsTuluvuud[tuluv]!.ungu.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(irtsTuluvuud[tuluv]!.ner,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: irtsTuluvuud[tuluv]!.ungu)),
                      ),
                  ]),
                ),
        ),
      ]),
    );
  }
}
