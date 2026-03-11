import 'dart:io';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../utils/responsive.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onLogout});
  final VoidCallback onLogout;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bio = BiometricService();
  bool _bioSupported = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBioState();
  }

  Future<void> _loadBioState() async {
    final supported = await _bio.isDeviceSupported();
    final enabled = await _bio.isEnabled();
    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    await _bio.setEnabled(value);
    if (!mounted) return;
    setState(() => _bioEnabled = value);

    final c = context.colors;
    final String bioType = Platform.isIOS ? 'Face ID' : 'Хурууны хээ';
    AppToast.show(
      context,
      value ? '$bioType идэвхжүүлсэн' : '$bioType идэвхгүй болсон',
      icon: Platform.isIOS ? Icons.face_unlock_rounded : Icons.fingerprint,
      color: value ? c.brandGreen : c.mutedForeground,
    );
  }

  Future<void> _confirmLogout(AppColorScheme c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout_rounded, color: c.destructive, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Гарах',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.primary,
              ),
            ),
          ],
        ),
        content: Text(
          'Та системээс гарахдаа итгэлтэй байна уу?',
          style: TextStyle(fontSize: 16, color: c.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Үгүй', style: TextStyle(color: c.mutedForeground)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.destructive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Гарах'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(); // close profile
      widget.onLogout(); // go to login
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Image.asset(
                'assets/images/zev_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Профайл',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User info Header ──
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: c.brandGreen.withOpacity(0.1),
                  child: Text(
                    AuthService.currentUser?.ner
                            .substring(0, 1)
                            .toUpperCase() ??
                        'U',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: c.brandGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AuthService.currentUser?.ovog} ${AuthService.currentUser?.ner}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: c.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ажилтан',
                        style: TextStyle(
                          fontSize: 14,
                          color: c.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── General Information ──
            Text(
              'Ерөнхий мэдээлэл',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              c: c,
              icon: Icons.business_rounded,
              label: 'Байгууллага',
              value: AuthService.currentUser?.baiguullagaNer ?? '-',
            ),
            _InfoRow(
              c: c,
              icon: Icons.phone_android_rounded,
              label: 'Утасны дугаар',
              value: AuthService.currentUser?.utas ?? '-',
            ),
            const SizedBox(height: 32),

            // ── Settings Section ──
            Text(
              'Тохиргоо',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 12),

            // ── Biometric Toggle ──
            if (_bioSupported)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Platform.isIOS ? Icons.face_unlock_rounded : Icons.fingerprint,
                        color: c.brandGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Platform.isIOS ? 'Face ID' : 'Хурууны хээ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: c.primary,
                            ),
                          ),
                          Text(
                            Platform.isIOS ? 'Face ID-р нэвтрэх' : 'Хурууны хээгээр нэвтрэх',
                            style: TextStyle(
                              fontSize: 14,
                              color: c.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _bioEnabled,
                      onChanged: _toggleBiometric,
                      activeColor: c.brandGreen,
                      activeTrackColor: c.brandGreen.withOpacity(0.3),
                    ),
                  ],
                ),
              ),

            if (!_bioSupported)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Platform.isIOS ? Icons.face_unlock_rounded : Icons.fingerprint,
                      color: c.mutedForeground,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Platform.isIOS
                            ? 'Энэ төхөөрөмж Face ID дэмжихгүй байна.'
                            : 'Энэ төхөөрөмж хурууны хээг дэмжихгүй байна.',
                        style: TextStyle(
                          fontSize: 15,
                          color: c.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── Other settings ──
            _SettingTile(
              c: c,
              icon: Icons.language_rounded,
              title: 'Хэл',
              subtitle: 'Монгол',
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: SettingsService(),
              builder: (context, _) {
                final themeMode = SettingsService().themeMode;
                final isDark = themeMode == ThemeMode.dark || 
                    (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
                    
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.dark_mode_rounded,
                          color: c.brandGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Харанхуй горим',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.primary,
                              ),
                            ),
                            Text(
                              themeMode == ThemeMode.system ? 'Системийн тохиргоо (Автомат)' : 'Гараар тохируулсан',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDark,
                        onChanged: (val) {
                          SettingsService().setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                        },
                        activeColor: c.brandGreen,
                        activeTrackColor: c.brandGreen.withOpacity(0.3),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // ── Dynamic Font Size ──
            ListenableBuilder(
              listenable: SettingsService(),
              builder: (context, _) {
                final factor = SettingsService().fontSizeFactor;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_size_rounded, color: c.mutedForeground, size: context.rIconSize(20)),
                          const SizedBox(width: 12),
                          Text('Үсгийн хэмжээ', style: TextStyle(
                            fontSize: context.rFontSize(16), 
                            color: c.primary,
                            fontWeight: FontWeight.w500,
                          )),
                          const Spacer(),
                          Text('${(factor * 100).toInt()}%', style: TextStyle(
                            fontSize: context.rFontSize(14),
                            color: c.brandGreen,
                            fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: c.brandGreen,
                          inactiveTrackColor: c.brandGreen.withOpacity(0.1),
                          thumbColor: c.brandGreen,
                          overlayColor: c.brandGreen.withOpacity(0.1),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        ),
                        child: Slider(
                          value: factor,
                          min: 0.8,
                          max: 1.5,
                          divisions: 7,
                          onChanged: (val) => SettingsService().setFontSizeFactor(val),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Жижиг', style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                          Text('Том', style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _SettingTile(
              c: c,
              icon: Icons.info_outline_rounded,
              title: 'Хувилбар',
              subtitle: '1.0.0',
            ),
            const SizedBox(height: 24),

            // ── Logout ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(c),
                icon: Icon(
                  Icons.logout_rounded,
                  color: c.destructive,
                  size: 20,
                ),
                label: Text('Гарах', style: TextStyle(color: c.destructive)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: c.destructive.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.c,
  });
  final String label, value;
  final Color color;
  final AppColorScheme c;

  @override
  Widget build(BuildContext _) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: c.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.c,
    required this.icon,
    required this.label,
    required this.value,
  });
  final AppColorScheme c;
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.mutedForeground),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: c.mutedForeground),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.c,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final AppColorScheme c;
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.mutedForeground, size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 16, color: c.primary)),
          const Spacer(),
          Text(
            subtitle,
            style: TextStyle(fontSize: 15, color: c.mutedForeground),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: c.mutedForeground),
        ],
      ),
    );
  }
}
