import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/irts_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'ajlyn_khuvaari_screen.dart';
import 'faq_screen.dart';
import 'irts_tailan_screen.dart';
import 'zuvshuurul_screen.dart';

const _brand = Color(0xFFF18F02);

/// Профайлын цэс (аватар дээр дарахад): хувийн мэдээлэл, ирцийн хуудсууд,
/// тохиргоо, тусламж, гарах.
class ProfailTsesScreen extends StatefulWidget {
  const ProfailTsesScreen({super.key, required this.onLogout, required this.irtsKharagdakh});
  final VoidCallback onLogout;
  final bool irtsKharagdakh;
  @override
  State<ProfailTsesScreen> createState() => _ProfailTsesScreenState();
}

class _ProfailTsesScreenState extends State<ProfailTsesScreen> {
  final _bio = BiometricService();
  bool _bioDemjikh = false;
  bool _bioIdevkhtei = false;
  String _khuvilbar = '';
  String? _barilgiinNer;

  @override
  void initState() {
    super.initState();
    _achaallaya();
  }

  Future<void> _achaallaya() async {
    final demjikh = await _bio.isDeviceSupported();
    final idevkhtei = await _bio.isEnabled();
    String khuvilbar = '';
    try {
      final info = await PackageInfo.fromPlatform();
      khuvilbar = info.version;
    } catch (_) {}
    String? barilga;
    if (widget.irtsKharagdakh) {
      try {
        barilga = (await IrtsService.barilgaAvya())?['ner']?.toString();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _bioDemjikh = demjikh;
      _bioIdevkhtei = idevkhtei;
      _khuvilbar = khuvilbar;
      _barilgiinNer = barilga;
    });
  }

  Future<void> _garakh() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Системээс гарах'),
        content: const Text('Та гарахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Болих')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Гарах'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    widget.onLogout();
  }

  Future<void> _irtsHolbokh() async {
    final holbov = await showDialog<bool>(context: context, builder: (_) => const _IrtsHolbokhDialog());
    if (holbov == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ирц бүртгэл холбогдлоо')),
      );
    }
  }

  void _neey(Widget khuudas) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => khuudas));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final u = AuthService.currentUser;
    final settings = SettingsService();
    final kharanhui = settings.themeMode == ThemeMode.dark ||
        (settings.themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final ner = u == null ? '' : (u.ovog.isNotEmpty ? '${u.ovog[0]}. ${u.ner}' : u.ner);

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: ListView(padding: EdgeInsets.zero, children: [
        // ── Толгой (Нүүртэй ижил градиент) ──
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF6B003), _brand, Color(0xFF3B2FA8)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(children: [
            Positioned(right: -40, top: -30, child: _Toirog(150, 0.10)),
            Positioned(left: -30, bottom: -40, child: _Toirog(110, 0.07)),
            Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 4, 12, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Хаах',
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.16)),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _tovch(u?.ner ?? ''),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ner,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500, color: Colors.white)),
                      if ((u?.albanTushaal ?? '').isNotEmpty)
                        Text(u!.albanTushaal, style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _TolgoiPill(
                    icon: Icons.apartment_rounded,
                    text: u?.baiguullagaNer.isNotEmpty == true ? u!.baiguullagaNer : 'Байгууллага',
                  ),
                  if (_barilgiinNer != null) _TolgoiPill(icon: Icons.location_on_rounded, text: _barilgiinNer!),
                ]),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Buleg(children: [
              _Mur(icon: Icons.person_rounded, iconUngu: const Color(0xFFF6B003), ner: 'Хувийн мэдээлэл', onTap: () => _neey(const _KhuviinMedeelel())),
              if (widget.irtsKharagdakh) ...[
                _Mur(icon: Icons.bar_chart_rounded, iconUngu: const Color(0xFF10B981), ner: 'Ажлын тайлан', onTap: () => _neey(const IrtsTailanScreen())),
                _Mur(icon: Icons.event_note_rounded, iconUngu: const Color(0xFFF59E0B), ner: 'Ажлын хуваарь', onTap: () => _neey(const AjlynKhuvaariScreen())),
              ],
            ]),
            const _BulgiinNer('Тохиргоо'),
            _Buleg(children: [
              _Mur(icon: Icons.settings_rounded, iconUngu: const Color(0xFF64748B), ner: 'Утасны тохиргоо', onTap: () => openAppSettings()),
              _Mur(
                icon: Icons.verified_user_rounded,
                iconUngu: const Color(0xFF14B8A6),
                ner: 'Байршил, мэдэгдлийн зөвшөөрөл',
                onTap: () => _neey(const ZuvshuurulScreen()),
              ),
              if (_bioDemjikh)
                _Mur(
                  icon: Icons.fingerprint_rounded,
                  iconUngu: const Color(0xFF0EA5E9),
                  ner: 'Биометрик ашиглах',
                  trailing: Switch(
                    value: _bioIdevkhtei,
                    activeTrackColor: _brand,
                    onChanged: (v) async {
                      await _bio.setEnabled(v);
                      await _bio.markAsked();
                      if (mounted) setState(() => _bioIdevkhtei = v);
                    },
                  ),
                ),
              _Mur(
                icon: Icons.dark_mode_rounded,
                iconUngu: const Color(0xFF7C3AED),
                ner: 'Харанхуй горим',
                trailing: Switch(
                  value: kharanhui,
                  activeTrackColor: _brand,
                  onChanged: (v) async {
                    await settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ]),
            // FSM хэрэглэгч irts бүртгэлээ холбоогүй бол л (ижил нэвтрэх нэртэй бол
            // нэвтрэхэд автоматаар холбогдож, Нүүрний товчлолд "Ирц" гарна)
            if (u != null && !u.irtsEsekh && !AuthService.khoyorBurtgeltei) ...[
              const _BulgiinNer('Холбосон бүртгэл'),
              _Buleg(children: [
                _Mur(
                  icon: Icons.add_link_rounded,
                  iconUngu: const Color(0xFF2563EB),
                  ner: 'Ирц бүртгэл холбох',
                  tailbar: 'irts.zevtabs.mn-ийн нэвтрэх нэрээрээ',
                  onTap: _irtsHolbokh,
                ),
              ]),
            ],
            const _BulgiinNer('Тусламж'),
            _Buleg(children: [
              // FAQScreen нь доод цонхонд зориулагдсан (апп-ын бусад хэсэгтэй ижил нээнэ)
              _Mur(
                icon: Icons.help_rounded,
                iconUngu: const Color(0xFFEC4899),
                ner: 'Түгээмэл асуулт',
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                    child: const FAQScreen(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _Buleg(children: [
              _Mur(icon: Icons.logout_rounded, iconUngu: const Color(0xFFE5484D), ner: 'Гарах', ungu: const Color(0xFFDC2626), onTap: _garakh),
            ]),
            if (_khuvilbar.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 6),
                child: Text('v $_khuvilbar', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
              ),
          ]),
        ),
      ]),
    );
  }

  static String _tovch(String ner) {
    final k = ner.replaceAll('.', ' ').trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return ((k.isNotEmpty ? k[0][0] : '') + (k.length > 1 ? k[1][0] : '')).toUpperCase();
  }
}

class _TolgoiPill extends StatelessWidget {
  const _TolgoiPill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ]),
      );
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

class _BulgiinNer extends StatelessWidget {
  const _BulgiinNer(this.ner);
  final String ner;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Text(ner, style: TextStyle(fontSize: 13.5, color: context.colors.mutedForeground)),
      );
}

class _Buleg extends StatelessWidget {
  const _Buleg({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Material: мөр дээр дарахад ripple харагдана
    return Material(
      color: c.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, color: c.border),
          children[i],
        ],
      ]),
    );
  }
}

class _Mur extends StatelessWidget {
  const _Mur({required this.icon, required this.ner, this.tailbar, this.onTap, this.trailing, this.ungu, this.iconUngu});
  final IconData icon;
  /// Дүрсний дэвсгэрийн өнгө (мөр бүр өөр)
  final Color? iconUngu;
  final String ner;
  final String? tailbar;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? ungu;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: onTap,
      minTileHeight: 58,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: iconUngu == null
          ? Icon(icon, color: ungu ?? c.primary)
          : Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(iconUngu, Colors.white, 0.22)!, iconUngu!],
                ),
              ),
              child: Icon(icon, size: 19, color: Colors.white),
            ),
      title: Text(ner, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ungu ?? c.primary)),
      subtitle: tailbar == null ? null : Text(tailbar!, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
      trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_right_rounded, color: c.mutedForeground)),
    );
  }
}

/// Хувийн мэдээлэл (зөвхөн харах)
class _KhuviinMedeelel extends StatelessWidget {
  const _KhuviinMedeelel();
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final u = AuthService.currentUser;
    final murnuud = <(String, String)>[
      ('Овог', u?.ovog ?? ''),
      ('Нэр', u?.ner ?? ''),
      ('Регистр', u?.register ?? ''),
      ('Утас', u?.utas ?? ''),
      ('Албан тушаал', u?.albanTushaal ?? ''),
      ('Байгууллага', u?.baiguullagaNer ?? ''),
      ('Эрх', u?.role ?? ''),
    ].where((m) => m.$2.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: c.loginBackground,
      appBar: AppBar(
        backgroundColor: c.loginBackground,
        surfaceTintColor: Colors.transparent,
        title: Text('Хувийн мэдээлэл', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: c.primary)),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _Buleg(children: [
          for (final m in murnuud)
            ListTile(
              title: Text(m.$1, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
              subtitle: Text(m.$2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.primary)),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Мэдээллээ засуулах бол удирдлагадаа хандана уу.',
              style: TextStyle(fontSize: 13, color: c.mutedForeground)),
        ),
      ]),
    );
  }
}

/// irts.zevtabs.mn-ийн нэр/нууц үгээр бүртгэл холбох цонх
class _IrtsHolbokhDialog extends StatefulWidget {
  const _IrtsHolbokhDialog();
  @override
  State<_IrtsHolbokhDialog> createState() => _IrtsHolbokhDialogState();
}

class _IrtsHolbokhDialogState extends State<_IrtsHolbokhDialog> {
  final _ner = TextEditingController();
  final _nuuts = TextEditingController();
  bool _ajillaj = false;
  String? _aldaa;

  @override
  void dispose() {
    _ner.dispose();
    _nuuts.dispose();
    super.dispose();
  }

  Future<void> _ilgeekh() async {
    if (_ner.text.trim().isEmpty || _nuuts.text.isEmpty) return;
    setState(() {
      _ajillaj = true;
      _aldaa = null;
    });
    final r = await AuthService.irtsHolbokh(_ner.text.trim(), _nuuts.text);
    if (!mounted) return;
    if (r.isSuccess) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _ajillaj = false;
        _aldaa = r.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: const Text('Ирц бүртгэл холбох'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('irts.zevtabs.mn-д нэвтэрдэг нэр, нууц үгээ оруулна уу.',
            style: TextStyle(fontSize: 13, color: c.mutedForeground)),
        const SizedBox(height: 12),
        TextField(
          controller: _ner,
          autofillHints: const [AutofillHints.username],
          decoration: const InputDecoration(labelText: 'Нэвтрэх нэр'),
        ),
        TextField(
          controller: _nuuts,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Нууц үг'),
          onSubmitted: (_) => _ilgeekh(),
        ),
        if (_aldaa != null) ...[
          const SizedBox(height: 10),
          Text(_aldaa!, style: TextStyle(fontSize: 13, color: c.destructive)),
        ],
      ]),
      actions: [
        TextButton(onPressed: _ajillaj ? null : () => Navigator.pop(context, false), child: const Text('Болих')),
        FilledButton(
          onPressed: _ajillaj ? null : _ilgeekh,
          child: _ajillaj
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Холбох'),
        ),
      ],
    );
  }
}
