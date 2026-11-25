import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/irts_service.dart';
import '../theme/app_theme.dart';

const _brand = Color(0xFF315BB0);
const _tabular = [FontFeature.tabularFigures()];
const _nuukhTulkhuur = 'tsalin_nuukh';

String _mungu(num? n) {
  final s = (n ?? 0).round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${(n ?? 0) < 0 ? '−' : ''}$b₮';
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

  String _u(num? n) => _nuukh ? '••••••₮' : _mungu(n);

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
        actions: [
          IconButton(
            tooltip: _nuukh ? 'Дүнг харуулах' : 'Дүнг нуух',
            onPressed: _nuukhSoliy,
            icon: Icon(_nuukh ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: c.primary),
          ),
        ],
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
                            Icon(Icons.account_balance_wallet_outlined, size: 56, color: c.mutedForeground.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('Батлагдсан цалин алга', style: TextStyle(fontSize: 16, color: c.primary)),
                            const SizedBox(height: 4),
                            Text('Нягтлан цалинг баталсны дараа энд харагдана.',
                                textAlign: TextAlign.center, style: TextStyle(color: c.mutedForeground)),
                          ]),
                        ),
                      if (t != null) ...[
                        // Сарууд
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _list.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final x = _list[i];
                              final songogdson = i == _i;
                              return ChoiceChip(
                                label: Text('${x['jil']}.${x['sar'].toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontFeatures: _tabular,
                                      color: songogdson ? _brand : c.mutedForeground,
                                      fontWeight: FontWeight.w500,
                                    )),
                                selected: songogdson,
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _i = i),
                                selectedColor: _brand.withValues(alpha: 0.1),
                                backgroundColor: c.cardBackground,
                                side: BorderSide(color: songogdson ? _brand : c.border),
                                shape: const StadiumBorder(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        _Kart(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${t['jil']} оны ${t['sar']}-р сар', style: TextStyle(fontSize: 15, color: c.mutedForeground)),
                            const SizedBox(height: 12),
                            IntrinsicHeight(
                              child: Row(children: [
                                Expanded(child: _Toim(ner: 'Үндсэн цалин', utga: _u(t['undsenTsalin']))),
                                VerticalDivider(color: c.border, width: 24),
                                Expanded(child: _Toim(ner: 'Гарт олгох', utga: _u(t['gartOlgokh']), tod: true)),
                              ]),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _Kart(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Ажилласан цаг', style: TextStyle(fontSize: 15, color: c.mutedForeground)),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: _Toim(ner: 'Ажиллах', utga: _tsag(t['fondTsag']), jijig: true)),
                              Expanded(child: _Toim(ner: 'Ажилласан', utga: _tsag(t['ajillasanTsag']), jijig: true)),
                              if (((t['iluuTsag'] as num?) ?? 0) > 0)
                                Expanded(child: _Toim(ner: 'Илүү цаг', utga: _tsag(t['iluuTsag']), jijig: true)),
                            ]),
                          ]),
                        ),
                        const SizedBox(height: 12),
                        _Kart(
                          child: Column(children: [
                            _Mur(ner: 'Бодогдсон цалин', utga: _u(t['bodogdsonTsalin'])),
                            if (((t['iluuTsagiinTsalin'] as num?) ?? 0) > 0)
                              _Mur(ner: 'Илүү цагийн цалин', utga: '+${_u(t['iluuTsagiinTsalin'])}', ungu: _brand),
                            for (final n in (t['nemegdeluud'] as List? ?? []))
                              _Mur(ner: n['ner'].toString(), utga: '+${_u(n['dun'])}', ungu: _brand),
                            if (((t['khotsroltSuutgal'] as num?) ?? 0) > 0)
                              _Mur(ner: 'Хоцролтын суутгал', utga: '−${_u(t['khotsroltSuutgal'])}', ungu: const Color(0xFFDC2626)),
                            _Mur(ner: 'Олговол зохих', utga: _u(t['olgovolZokhikh']), zuraastai: true),
                            _Mur(ner: 'НДШ', utga: '−${_u(t['ndsh'])}', ungu: c.mutedForeground),
                            _Mur(ner: 'ХХОАТ', utga: '−${_u(t['khkhoat'])}', ungu: c.mutedForeground),
                            for (final s in (t['suutgaluud'] as List? ?? []))
                              _Mur(ner: s['ner'].toString(), utga: '−${_u(s['dun'])}', ungu: const Color(0xFFDC2626)),
                            _Mur(ner: 'Гарт олгох', utga: _u(t['gartOlgokh']), zuraastai: true, tod: true),
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

class _Toim extends StatelessWidget {
  const _Toim({required this.ner, required this.utga, this.tod = false, this.jijig = false});
  final String ner, utga;
  final bool tod, jijig;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(ner, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(utga,
            style: TextStyle(
              fontSize: jijig ? 18 : 24,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
              color: tod ? _brand : c.primary,
              fontFeatures: _tabular,
            )),
      ),
    ]);
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
