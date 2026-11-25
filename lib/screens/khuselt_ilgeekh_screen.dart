import 'package:flutter/material.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';

const _brand = Color(0xFF315BB0);
const _tabular = [FontFeature.tabularFigures()];

/// irtsBack-ийн дэмждэг хүсэлтийн төрлүүд
class KhuseltTurul {
  const KhuseltTurul(this.key, this.ner, this.tailbar, this.icon, this.buleg);
  final String key; // chuluu | eelj | uvchiin
  final String ner;
  final String tailbar;
  final IconData icon;
  final String buleg;
}

const khuseltTurluud = [
  KhuseltTurul('chuluu', 'Чөлөө', 'Цагаар чөлөө авах', Icons.schedule_rounded, 'Ажиллаагүй'),
  KhuseltTurul('eelj', 'Ээлжийн амралт', 'Хоногоор амрах', Icons.beach_access_rounded, 'Амралт'),
  KhuseltTurul('uvchiin', 'Өвчтэй', 'Эмнэлгийн чөлөө', Icons.healing_rounded, 'Амралт'),
];

/// Төрөл сонгох доод цонх (бүлэглэсэн жагсаалт)
Future<KhuseltTurul?> khuseltTurulSongokh(BuildContext context, {KhuseltTurul? odoo}) {
  FocusManager.instance.primaryFocus?.unfocus();
  final c = context.colors;
  return showModalBottomSheet<KhuseltTurul>(
    context: context,
    useSafeArea: true,
    // Намхан дэлгэцэд (SE, хэвтээ утас) жагсаалт гүйлгэгдэнэ
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    backgroundColor: c.cardBackground,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      final bulguud = <String, List<KhuseltTurul>>{};
      for (final t in khuseltTurluud) {
        bulguud.putIfAbsent(t.buleg, () => []).add(t);
      }
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Хүсэлтийн төрөл сонгох', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.primary)),
          const SizedBox(height: 12),
          for (final b in bulguud.entries) ...[
            Container(
              width: double.infinity,
              color: c.muted,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(b.key, style: TextStyle(fontSize: 13.5, color: c.mutedForeground)),
            ),
            for (final t in b.value)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(t.icon, color: t == odoo ? _brand : c.mutedForeground),
                title: Text(t.ner, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.primary)),
                subtitle: Text(t.tailbar, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                trailing: t == odoo ? const Icon(Icons.check_rounded, color: _brand) : null,
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
          const SizedBox(height: 12),
          ]),
        ),
      );
    },
  );
}

/// Хүсэлт илгээх хуудас
class KhuseltIlgeekhScreen extends StatefulWidget {
  const KhuseltIlgeekhScreen({super.key, required this.turul});
  final KhuseltTurul turul;
  @override
  State<KhuseltIlgeekhScreen> createState() => _KhuseltIlgeekhScreenState();
}

class _KhuseltIlgeekhScreenState extends State<KhuseltIlgeekhScreen> {
  late KhuseltTurul _turul = widget.turul;
  DateTime _ekh = DateTime.now();
  DateTime _tug = DateTime.now();
  TimeOfDay _tsagEkh = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _tsagTug = const TimeOfDay(hour: 12, minute: 0);
  final _tailbar = TextEditingController();
  bool _ilgeej = false;
  String? _aldaa;

  @override
  void dispose() {
    _tailbar.dispose();
    super.dispose();
  }

  String _t(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _d(DateTime d) => '${d.year} / ${d.month.toString().padLeft(2, '0')} / ${d.day.toString().padLeft(2, '0')}';

  Future<void> _ognoo(bool ekhlel) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: ekhlel ? _ekh : _tug,
      firstDate: DateTime(now.year, now.month - 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d == null) return;
    setState(() {
      if (ekhlel) {
        _ekh = d;
        if (_tug.isBefore(d)) _tug = d;
      } else {
        _tug = d.isBefore(_ekh) ? _ekh : d;
      }
    });
  }

  Future<void> _tsag(bool ekhlel) async {
    final t = await showTimePicker(
      context: context,
      initialTime: ekhlel ? _tsagEkh : _tsagTug,
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t != null) setState(() => ekhlel ? _tsagEkh = t : _tsagTug = t);
  }

  Future<void> _ilgeeye() async {
    if (_tailbar.text.trim().isEmpty) {
      setState(() => _aldaa = 'Тайлбараа бичнэ үү.');
      return;
    }
    setState(() {
      _ilgeej = true;
      _aldaa = null;
    });
    try {
      if (_turul.key == 'chuluu') {
        await IrtsService.chuluuKhuseltIlgeeye(
          ognoo: _ekh,
          duusakhOgnoo: _tug,
          ekhlekhTsag: _t(_tsagEkh),
          duusakhTsag: _t(_tsagTug),
          tailbar: _tailbar.text.trim(),
        );
      } else {
        await IrtsService.amraltKhuseltIlgeeye(
          ekhlekhOgnoo: _ekh,
          duusakhOgnoo: _tug,
          turul: _turul.key,
          tailbar: _tailbar.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _aldaa = e.toString());
    } finally {
      if (mounted) setState(() => _ilgeej = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chuluu = _turul.key == 'chuluu';
    return Scaffold(
      backgroundColor: c.loginBackground,
      appBar: AppBar(
        backgroundColor: c.cardBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Буцах',
          icon: const Icon(Icons.arrow_back_rounded, color: _brand),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Хүсэлт илгээх', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.primary)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
            _Kart(
              onTap: () async {
                final t = await khuseltTurulSongokh(context, odoo: _turul);
                if (t != null) setState(() => _turul = t);
              },
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Хүсэлтийн төрөл', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
                    const SizedBox(height: 2),
                    Text(_turul.ner, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _brand)),
                  ]),
                ),
                Icon(Icons.chevron_right_rounded, color: c.mutedForeground),
              ]),
            ),
            const SizedBox(height: 12),
            _Kart(
              child: Column(children: [
                _OgnooMur(ner: chuluu ? 'Огноо' : 'Эхлэх', utga: _d(_ekh), onTap: () => _ognoo(true)),
                Divider(height: 20, color: c.border),
                _OgnooMur(ner: 'Дуусах', utga: _d(_tug), onTap: () => _ognoo(false)),
                if (chuluu) ...[
                  Divider(height: 20, color: c.border),
                  _OgnooMur(ner: 'Цаг', utga: '${_t(_tsagEkh)}  –', onTap: () => _tsag(true), khoyrdugaar: _t(_tsagTug), onTap2: () => _tsag(false)),
                ],
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Icon(Icons.description_outlined, size: 20, color: c.mutedForeground),
              const SizedBox(width: 8),
              Text('Тайлбар', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary)),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _tailbar,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              minLines: 4,
              maxLines: 6,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Тайлбараа бичнэ үү',
                filled: true,
                fillColor: c.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _brand, width: 1.5),
                ),
              ),
            ),
            if (_aldaa != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_aldaa!, style: TextStyle(color: c.destructive, fontSize: 13)),
              ),
          ]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(color: c.cardBackground, border: Border(top: BorderSide(color: c.border))),
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    backgroundColor: _brand.withValues(alpha: 0.08),
                    foregroundColor: _brand,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Цуцлах', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _ilgeej ? null : _ilgeeye,
                  style: FilledButton.styleFrom(backgroundColor: _brand, shape: const StadiumBorder()),
                  child: Text(_ilgeej ? 'Илгээж байна' : 'Илгээх',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Kart extends StatelessWidget {
  const _Kart({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _OgnooMur extends StatelessWidget {
  const _OgnooMur({required this.ner, required this.utga, required this.onTap, this.khoyrdugaar, this.onTap2});
  final String ner, utga;
  final VoidCallback onTap;
  final String? khoyrdugaar;
  final VoidCallback? onTap2;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tovch(String t, VoidCallback f) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: f,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(10)),
            child: Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
          ),
        );
    return Row(children: [
      Text(ner, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.primary)),
      const Spacer(),
      tovch(utga, onTap),
      if (khoyrdugaar != null) ...[const SizedBox(width: 8), tovch(khoyrdugaar!, onTap2!)],
    ]);
  }
}
