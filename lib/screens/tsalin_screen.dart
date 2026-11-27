import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';

const _brand = Color(0xFFF18F02);
const _tabular = [FontFeature.tabularFigures()];
const _nuukhTulkhuur = 'tsalin_nuukh';

String _mungu(num? n) {
  final s = (n ?? 0).round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${(n ?? 0) < 0 ? '−' : ''}$b';
}

String _tsag(num? t) {
  final m = ((t ?? 0) * 60).round();
  return '${m ~/ 60}ц ${m % 60}м';
}

/// Цалин: батлагдсан сарын цалингийн задаргаа (нууж/харуулах боломжтой)
class TsalinScreen extends StatefulWidget {
  const TsalinScreen({super.key});
  @override
  State<TsalinScreen> createState() => _TsalinScreenState();
}

class _TsalinScreenState extends State<TsalinScreen> {
  List<Map<String, dynamic>> _list = [];
  int _i = 0;
  bool _nuukh = false;
  bool _achaallaj = true;
  String? _aldaa;

  @override
  void initState() {
    super.initState();
    _achaallaya();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _nuukh = p.getBool(_nuukhTulkhuur) ?? false);
    });
  }

  Future<void> _achaallaya() async {
    try {
      final list = await IrtsService.miniiTsalin();
      if (mounted) {
        setState(() {
          _list = list;
          _i = 0;
          _aldaa = null;
          _achaallaj = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aldaa = e is IrtsAldaa ? e.message : 'Цалингийн мэдээлэл авч чадсангүй.';
          _achaallaj = false;
        });
      }
    }
  }

  Future<void> _nuukhSoliy() async {
    setState(() => _nuukh = !_nuukh);
    (await SharedPreferences.getInstance()).setBool(_nuukhTulkhuur, _nuukh);
  }

  String _u(num? n) => _nuukh ? '••••••' : _mungu(n);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = _list.isEmpty ? null : _list[_i];
    return Scaffold(
      backgroundColor: c.loginBackground,
      appBar: AppBar(
        backgroundColor: c.loginBackground,
        surfaceTintColor: Colors.transparent,
        title: Text('Цалин', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: c.primary)),
      ),
      body: _achaallaj
          ? const Center(child: CircularProgressIndicator(color: _brand))
          : RefreshIndicator(
              color: _brand,
              onRefresh: _achaallaya,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      if (_aldaa != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_aldaa!, style: TextStyle(color: c.destructive)),
                        ),
                      if (t == null && _aldaa == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  const Color(0xFF8B5CF6).withValues(alpha: 0.16),
                                  _brand.withValues(alpha: 0.12),
                                ]),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, size: 42, color: Color(0xFF8B5CF6)),
                            ),
                            const SizedBox(height: 14),
                            Text('Батлагдсан цалин алга', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.primary)),
                            const SizedBox(height: 4),
                            Text('Нягтлан цалинг баталсны дараа энд харагдана.',
                                textAlign: TextAlign.center, style: TextStyle(color: c.mutedForeground)),
                          ]),
                        ),
                      if (t != null) ...[
                        // Сарууд
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _list.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final x = _list[i];
                              final songogdson = i == _i;
                              return GestureDetector(
                                onTap: () => setState(() => _i = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: songogdson
                                        ? const LinearGradient(colors: [Color(0xFFF6B003), _brand])
                                        : null,
                                    color: songogdson ? null : _brand.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text('${x['jil']}.${x['sar'].toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontFeatures: _tabular,
                                        color: songogdson ? Colors.white : _brand,
                                      )),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Гарт олгох — гол карт
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 18, 12, 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF6B003), _brand, Color(0xFF4C3FC9)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: _brand.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(
                                child: Text('${t['jil']} оны ${t['sar']}-р сар · Гарт олгох',
                                    style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85))),
                              ),
                              IconButton(
                                tooltip: _nuukh ? 'Дүнг харуулах' : 'Дүнг нуух',
                                onPressed: _nuukhSoliy,
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.16)),
                                icon: Icon(_nuukh ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 20, color: Colors.white),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('${_u(t['gartOlgokh'])} ₮',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                    fontFeatures: _tabular,
                                  )),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                Icon(Icons.payments_rounded, size: 18, color: Colors.white.withValues(alpha: 0.85)),
                                const SizedBox(width: 8),
                                Text('Үндсэн цалин', style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85))),
                                const Spacer(),
                                Text('${_u(t['undsenTsalin'])} ₮',
                                    style: const TextStyle(fontSize: 14.5, color: Colors.white, fontFeatures: _tabular)),
                              ]),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        // Цаг
                        Builder(builder: (_) {
                          final fond = (t['fondTsag'] as num?) ?? 0;
                          final ajillasan = (t['ajillasanTsag'] as num?) ?? 0;
                          final iluu = (t['iluuTsag'] as num?) ?? 0;
                          return _Kart(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: _TsagTile(icon: Icons.event_note_rounded, ner: 'Ажиллах', utga: _tsag(fond), ungu: _brand)),
                                const SizedBox(width: 8),
                                Expanded(child: _TsagTile(icon: Icons.timer_rounded, ner: 'Ажилласан', utga: _tsag(ajillasan), ungu: const Color(0xFF059669))),
                                if (iluu > 0) ...[
                                  const SizedBox(width: 8),
                                  Expanded(child: _TsagTile(icon: Icons.more_time_rounded, ner: 'Илүү цаг', utga: _tsag(iluu), ungu: const Color(0xFF8B5CF6))),
                                ],
                              ]),
                              if (fond > 0) ...[
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: (ajillasan / fond).clamp(0.0, 1.0).toDouble(),
                                    minHeight: 8,
                                    backgroundColor: _brand.withValues(alpha: 0.10),
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('Ажиллах цагийн ${((ajillasan / fond) * 100).clamp(0, 999).round()}% ажилласан',
                                    style: TextStyle(fontSize: 12.5, color: c.mutedForeground)),
                              ],
                            ]),
                          );
                        }),
                        const SizedBox(height: 14),
                        // Задаргаа
                        _Kart(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _Garchig(icon: Icons.add_circle_rounded, ner: 'Цалин, нэмэгдэл', ungu: const Color(0xFF059669)),
                            _Mur(ner: 'Бодогдсон цалин', utga: _u(t['bodogdsonTsalin'])),
                            if (((t['iluuTsagiinTsalin'] as num?) ?? 0) > 0)
                              _Mur(ner: 'Илүү цагийн цалин', utga: '+${_u(t['iluuTsagiinTsalin'])}', ungu: const Color(0xFF059669)),
                            for (final n in (t['nemegdeluud'] as List? ?? []))
                              _Mur(ner: n['ner'].toString(), utga: '+${_u(n['dun'])}', ungu: const Color(0xFF059669)),
                            _Mur(ner: 'Олговол зохих', utga: _u(t['olgovolZokhikh']), zuraastai: true),
                            const SizedBox(height: 10),
                            _Garchig(icon: Icons.remove_circle_rounded, ner: 'Суутгал', ungu: const Color(0xFFE5484D)),
                            if (((t['khotsroltSuutgal'] as num?) ?? 0) > 0)
                              _Mur(ner: 'Хоцролтын суутгал', utga: '−${_u(t['khotsroltSuutgal'])}', ungu: const Color(0xFFE5484D)),
                            _Mur(ner: 'НДШ', utga: '−${_u(t['ndsh'])}', ungu: const Color(0xFFE5484D)),
                            _Mur(ner: 'ХХОАТ', utga: '−${_u(t['khkhoat'])}', ungu: const Color(0xFFE5484D)),
                            for (final s in (t['suutgaluud'] as List? ?? []))
                              _Mur(ner: s['ner'].toString(), utga: '−${_u(s['dun'])}', ungu: const Color(0xFFE5484D)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _brand.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                Text('Гарт олгох', style: TextStyle(fontSize: 15, color: c.primary)),
                                const Spacer(),
                                Text('${_u(t['gartOlgokh'])} ₮',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: _brand, fontFeatures: _tabular)),
                              ]),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _Kart extends StatelessWidget {
  const _Kart({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

class _TsagTile extends StatelessWidget {
  const _TsagTile({required this.icon, required this.ner, required this.utga, required this.ungu});
  final IconData icon;
  final String ner, utga;
  final Color ungu;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: ungu.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: ungu),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(utga, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.primary, fontFeatures: _tabular)),
        ),
        Text(ner, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
      ]),
    );
  }
}

class _Garchig extends StatelessWidget {
  const _Garchig({required this.icon, required this.ner, required this.ungu});
  final IconData icon;
  final String ner;
  final Color ungu;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Icon(icon, size: 18, color: ungu),
        const SizedBox(width: 6),
        Text(ner, style: TextStyle(fontSize: 13.5, color: ungu)),
      ]),
    );
  }
}

class _Mur extends StatelessWidget {
  const _Mur({required this.ner, required this.utga, this.ungu, this.zuraastai = false, this.tod = false});
  final String ner, utga;
  final Color? ungu;
  final bool zuraastai, tod;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: zuraastai ? BoxDecoration(border: Border(top: BorderSide(color: c.border))) : null,
      child: Row(children: [
        Expanded(child: Text(ner, style: TextStyle(fontSize: 15, color: tod ? c.primary : c.mutedForeground))),
        Text(utga,
            style: TextStyle(
              fontSize: tod ? 17 : 15,
              fontWeight: FontWeight.w500,
              color: tod ? _brand : (ungu ?? c.primary),
              fontFeatures: _tabular,
            )),
      ]),
    );
  }
}
