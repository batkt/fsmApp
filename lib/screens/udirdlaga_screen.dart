import 'package:flutter/material.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';
import '../utils/irts_logic.dart';

const _brand = Color(0xFFF18F02);
const _tabular = [FontFeature.tabularFigures()];

String _hm(DateTime? d) =>
    d == null ? '—' : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _md(DateTime? d) =>
    d == null ? '' : '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// Удирдлага (Admin): өдрийн бүх ажилтны ирц + чөлөө/амралтын хүсэлт шийдвэрлэх.
class UdirdlagaScreen extends StatefulWidget {
  const UdirdlagaScreen({super.key});
  @override
  State<UdirdlagaScreen> createState() => _UdirdlagaScreenState();
}

class _UdirdlagaScreenState extends State<UdirdlagaScreen> {
  int _tab = 0;
  DateTime _udur = DateTime.now();
  List<Map<String, dynamic>> _ajiltnuud = [];
  List<Map<String, dynamic>> _irtsuud = [];
  List<Map<String, dynamic>> _khuseltuud = [];
  bool _achaallaj = true;
  String? _aldaa;
  String? _shuult; // төлөвөөр шүүх

  @override
  void initState() {
    super.initState();
    _achaallaya();
  }

  Future<void> _achaallaya() async {
    setState(() => _achaallaj = true);
    try {
      await IrtsService.barilgaAvya();
      final res = await Future.wait([
        IrtsService.ajiltnuud(),
        IrtsService.odriinBukhIrts(_udur),
        IrtsService.bukhKhuseltuud(),
      ]);
      if (!mounted) return;
      setState(() {
        _ajiltnuud = res[0];
        _irtsuud = res[1];
        _khuseltuud = res[2];
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

  Future<void> _udurSoliy(int n) async {
    setState(() {
      _udur = _udur.add(Duration(days: n));
      _shuult = null;
    });
    try {
      final list = await IrtsService.odriinBukhIrts(_udur);
      if (mounted) setState(() => _irtsuud = list);
    } catch (_) {}
  }

  Future<void> _shiidvel(Map h, String tuluv) async {
    String? shaltgaan;
    if (tuluv == 'tatgalzsan') {
      shaltgaan = await _shaltgaanAsuuya();
      if (shaltgaan == null) return;
    }
    try {
      await IrtsService.khuseltShiidvel(h, tuluv, shaltgaan: shaltgaan);
      _medegdel(tuluv == 'zuvshurulusen' ? 'Зөвшөөрлөө' : 'Татгалзлаа');
      final list = await IrtsService.bukhKhuseltuud();
      if (mounted) setState(() => _khuseltuud = list);
    } catch (e) {
      _medegdel(e.toString(), aldaa: true);
    }
  }

  Future<String?> _shaltgaanAsuuya() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Татгалзах шалтгаан'),
        content: TextField(
          controller: ctrl,
          onTapOutside: (_) => FocusScope.of(ctx).unfocus(),
          autofocus: true,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(hintText: 'Ажилтанд харагдана', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Болих')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Татгалзах'),
          ),
        ],
      ),
    );
  }

  void _medegdel(String text, {bool aldaa = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      backgroundColor: aldaa ? context.colors.destructive : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final khuleegdej = _khuseltuud.where((h) => h['tuluv'] == 'huvlaj_baina').length;
    return Scaffold(
      backgroundColor: c.loginBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              color: _brand,
              onRefresh: _achaallaya,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(99)),
                    child: Row(children: [
                      _Tab(ner: 'Өдрийн ирц', songogdson: _tab == 0, onTap: () => setState(() => _tab = 0)),
                      _Tab(ner: 'Хүсэлт', too: khuleegdej, songogdson: _tab == 1, onTap: () => setState(() => _tab = 1)),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  if (_aldaa != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_aldaa!, style: TextStyle(color: c.destructive)),
                    ),
                  if (_achaallaj)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator(color: _brand)),
                    )
                  else if (_tab == 0)
                    ..._irtsKhesek(c)
                  else
                    ..._khuseltKhesek(c),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Өдрийн ирц ──
  List<Widget> _irtsKhesek(AppColorScheme c) {
    final now = DateTime.now();
    final unuudur = _udur.year == now.year && _udur.month == now.month && _udur.day == now.day;
    final irtsMap = {for (final x in _irtsuud) x['ajiltniiId']?.toString(): x};
    final murnuud = [
      for (final a in _ajiltnuud)
        (ajiltan: a, irts: irtsMap[a['_id']?.toString()], tuluv: bichlegiinTuluv(irtsMap[a['_id']?.toString()]) ?? 'irgeegui'),
    ];
    final toonuud = <String, int>{};
    var ajillasan = 0, khotsrolt = 0;
    for (final m in murnuud) {
      toonuud[m.tuluv] = (toonuud[m.tuluv] ?? 0) + 1;
      ajillasan += (m.irts?['ajillasanMinut'] as num?)?.round() ?? 0;
      khotsrolt += (m.irts?['khotsorsonMinut'] as num?)?.round() ?? 0;
    }
    const daraalal = ['khotsorson', 'tasalsan', 'irgeegui', 'hagas', 'chuluu', 'amralt', 'kheviin'];
    murnuud.sort((a, b) => daraalal.indexOf(a.tuluv).compareTo(daraalal.indexOf(b.tuluv)));
    final kharagdakh = _shuult == null ? murnuud : murnuud.where((m) => m.tuluv == _shuult).toList();

    return [
      Row(children: [
        IconButton(onPressed: () => _udurSoliy(-1), tooltip: 'Өмнөх өдөр', icon: Icon(Icons.chevron_left_rounded, color: c.primary)),
        Expanded(
          child: Text(unuudur ? 'Өнөөдөр, ${_md(_udur)}' : '${_udur.year}.${_md(_udur)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
        ),
        IconButton(
          onPressed: unuudur ? null : () => _udurSoliy(1),
          tooltip: 'Дараах өдөр',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ]),
      const SizedBox(height: 8),
      // Нэгтгэл
      LayoutBuilder(builder: (context, box) {
        final bagana = box.maxWidth >= 600 ? 4 : 2;
        const zai = 10.0;
        final w = (box.maxWidth - zai * (bagana - 1)) / bagana;
        final kartuud = [
          _Stat(ner: 'Ажилтан', utga: '${murnuud.length}', icon: Icons.groups_rounded, ungu: const Color(0xFF2563EB)),
          _Stat(ner: 'Ажилласан', utga: tsagMinutTekst(ajillasan), icon: Icons.schedule_rounded, ungu: _brand),
          _Stat(
            ner: 'Хоцролт',
            utga: khotsrolt == 0 ? '0' : tsagMinutTekst(khotsrolt),
            icon: Icons.hourglass_bottom_rounded,
            ungu: const Color(0xFFDC2626),
          ),
          _Stat(
            ner: 'Ирээгүй',
            utga: '${toonuud['irgeegui'] ?? 0}',
            icon: Icons.person_off_outlined,
            ungu: const Color(0xFF64748B),
          ),
        ];
        return Wrap(spacing: zai, runSpacing: zai, children: [for (final k in kartuud) SizedBox(width: w, child: k)]);
      }),
      const SizedBox(height: 12),
      // Төлөвөөр шүүх
      SizedBox(
        height: 36,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _Chip(ner: 'Бүгд ${murnuud.length}', idevkhtei: _shuult == null, onTap: () => setState(() => _shuult = null)),
          for (final k in daraalal)
            if ((toonuud[k] ?? 0) > 0)
              _Chip(
                ner: '${k == 'irgeegui' ? 'Ирээгүй' : irtsTuluvuud[k]!.ner} ${toonuud[k]}',
                ungu: k == 'irgeegui' ? const Color(0xFF94A3B8) : irtsTuluvuud[k]!.ungu,
                idevkhtei: _shuult == k,
                onTap: () => setState(() => _shuult = _shuult == k ? null : k),
              ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: c.cardBackground, borderRadius: BorderRadius.circular(20)),
        child: kharagdakh.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _ajiltnuud.isEmpty ? 'Энэ барилгад ажилтан бүртгэгдээгүй байна.' : 'Шүүлтэд тохирох ажилтан алга.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.mutedForeground),
                ),
              )
            : Column(children: [
                for (var i = 0; i < kharagdakh.length; i++)
                  _AjiltanMur(
                    ajiltan: kharagdakh[i].ajiltan,
                    irts: kharagdakh[i].irts,
                    tuluv: kharagdakh[i].tuluv,
                    suuliin: i == kharagdakh.length - 1,
                  ),
              ]),
      ),
    ];
  }

  // ── Хүсэлт ──
  List<Widget> _khuseltKhesek(AppColorScheme c) {
    final khuleegdej = _khuseltuud.where((h) => h['tuluv'] == 'huvlaj_baina').toList();
    final shiidsen = _khuseltuud.where((h) => h['tuluv'] != 'huvlaj_baina').take(30).toList();
    return [
      if (khuleegdej.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('Шийдвэрлэх хүсэлт алга.', textAlign: TextAlign.center, style: TextStyle(color: c.mutedForeground)),
        )
      else
        for (final h in khuleegdej)
          _KhuseltKart(h: h, onZuvshuurukh: () => _shiidvel(h, 'zuvshurulusen'), onTatgalzakh: () => _shiidvel(h, 'tatgalzsan')),
      if (shiidsen.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text('Шийдвэрлэсэн', style: TextStyle(fontSize: 14, color: c.mutedForeground)),
        ),
        for (final h in shiidsen) _KhuseltKart(h: h),
      ],
    ];
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.ner, required this.songogdson, required this.onTap, this.too = 0});
  final String ner;
  final bool songogdson;
  final VoidCallback onTap;
  final int too;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: songogdson ? c.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(ner,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: songogdson ? FontWeight.w500 : FontWeight.w500,
                  color: songogdson ? _brand : c.mutedForeground,
                )),
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
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.ner, required this.utga, required this.icon, required this.ungu});
  final String ner, utga;
  final IconData icon;
  final Color ungu;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.cardBackground, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: ungu.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: ungu),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ner, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(utga,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ungu, fontFeatures: _tabular)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.ner, required this.idevkhtei, required this.onTap, this.ungu});
  final String ner;
  final bool idevkhtei;
  final VoidCallback onTap;
  final Color? ungu;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          if (ungu != null) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: ungu, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(ner),
        ]),
        selected: idevkhtei,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: _brand.withValues(alpha: 0.14),
        backgroundColor: c.cardBackground,
        side: BorderSide(color: idevkhtei ? _brand : c.border),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: idevkhtei ? _brand : c.primary,
          fontFeatures: _tabular,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _AjiltanMur extends StatelessWidget {
  const _AjiltanMur({required this.ajiltan, required this.irts, required this.tuluv, required this.suuliin});
  final Map ajiltan;
  final Map? irts;
  final String tuluv;
  final bool suuliin;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ner = ajiltan['ner']?.toString() ?? '';
    final ovog = ajiltan['ovog']?.toString() ?? '';
    final ungu = tuluv == 'irgeegui' ? const Color(0xFF94A3B8) : irtsTuluvuud[tuluv]!.ungu;
    final tuluvNer = tuluv == 'irgeegui' ? 'Ирээгүй' : irtsTuluvuud[tuluv]!.ner;
    final khotsorson = (irts?['khotsorsonMinut'] as num?)?.round() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(border: suuliin ? null : Border(bottom: BorderSide(color: c.border))),
      child: Row(children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: ungu.withValues(alpha: 0.14),
          child: Text(ner.isEmpty ? '?' : ner[0].toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w500, color: ungu)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ovog.isNotEmpty ? '${ovog[0]}.$ner' : ner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary)),
            Text(
              '${_hm(ognooUnshikh(irts?['irsenTsag']))} – ${_hm(ognooUnshikh(irts?['yawsanTsag']))}',
              style: TextStyle(fontSize: 13, color: c.mutedForeground, fontFeatures: _tabular),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: ungu.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
          child: Text(khotsorson > 0 ? '$tuluvNer $khotsorson мин' : tuluvNer,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ungu)),
        ),
      ]),
    );
  }
}

class _KhuseltKart extends StatelessWidget {
  const _KhuseltKart({required this.h, this.onZuvshuurukh, this.onTatgalzakh});
  final Map h;
  final VoidCallback? onZuvshuurukh;
  final VoidCallback? onTatgalzakh;

  String get _turul {
    if (h['turulKhuselt'] == 'chuluu') return 'Чөлөө';
    return h['turul'] == 'uvchiin' ? 'Өвчтэй' : 'Ээлжийн амралт';
  }

  String get _khugatsaa {
    if (h['turulKhuselt'] == 'chuluu') {
      final a = ognooUnshikh(h['ognoo']);
      final b = ognooUnshikh(h['duusakhOgnoo']);
      final udur = b != null && _md(a) != _md(b) ? '${_md(a)}–${_md(b)}' : _md(a);
      return '$udur, ${h['ekhlekhTsag'] ?? ''}–${h['duusakhTsag'] ?? ''}';
    }
    final a = ognooUnshikh(h['ekhlekhOgnoo']);
    final b = ognooUnshikh(h['duusakhOgnoo']);
    final khonog = a != null && b != null ? b.difference(a).inDays + 1 : null;
    return '${_md(a)}–${_md(b)}${khonog != null ? ', $khonog хоног' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final khuleegdej = h['tuluv'] == 'huvlaj_baina';
    final zuvshuursun = h['tuluv'] == 'zuvshurulusen';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: c.cardBackground, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(h['ajiltniiNer']?.toString() ?? '—',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (h['turulKhuselt'] == 'chuluu' ? const Color(0xFF0EA5E9) : const Color(0xFF8B5CF6)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(_turul,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: h['turulKhuselt'] == 'chuluu' ? const Color(0xFF0284C7) : const Color(0xFF7C3AED),
                )),
          ),
        ]),
        const SizedBox(height: 4),
        Text(_khugatsaa, style: TextStyle(fontSize: 13.5, color: c.mutedForeground, fontFeatures: _tabular)),
        if ((h['tailbar'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(h['tailbar'].toString(), style: TextStyle(fontSize: 14, color: c.primary)),
        ],
        if (khuleegdej && onZuvshuurukh != null) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onTatgalzakh,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Татгалзах', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onZuvshuurukh,
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Зөвшөөрөх', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
          ]),
        ] else if (!khuleegdej) ...[
          const SizedBox(height: 6),
          Text(
            zuvshuursun
                ? 'Зөвшөөрсөн${h['zuvshuruluusenAjiltniiNer'] != null ? ', ${h['zuvshuruluusenAjiltniiNer']}' : ''}'
                : 'Татгалзсан${(h['tatgalzsanShaltgaan'] ?? '').toString().isNotEmpty ? ': ${h['tatgalzsanShaltgaan']}' : ''}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: zuvshuursun ? _brand : const Color(0xFFDC2626),
            ),
          ),
        ],
      ]),
    );
  }
}
