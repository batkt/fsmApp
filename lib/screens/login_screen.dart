import 'package:flutter/material.dart';

import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});
  final VoidCallback onLoggedIn;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  final _bio = BiometricService();
  bool _bioSupported = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final supported = await _bio.isDeviceSupported();
    final enabled = await _bio.isEnabled();
    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = enabled;
    });

    // Auto-trigger biometric if enabled
    if (supported && enabled) {
      _handleBiometricLogin();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // After successful login, ask about biometric if not asked yet
    await _maybeAskBiometric();

    if (!mounted) return;
    widget.onLoggedIn();
  }

  Future<void> _handleBiometricLogin() async {
    if (!_bioSupported || !_bioEnabled) return;
    final authenticated = await _bio.authenticate();
    if (authenticated && mounted) {
      widget.onLoggedIn();
    }
  }

  Future<void> _maybeAskBiometric() async {
    if (!_bioSupported) return;
    final asked = await _bio.wasAsked();
    if (asked) return;
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = ctx.colors;
        return AlertDialog(
          backgroundColor: c.cardBackground,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.brandGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.fingerprint,
                  color: c.brandGreen, size: 28)),
            const SizedBox(width: 12),
            Expanded(child: Text('Хурууны хээ',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: c.primary))),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Дараагийн удаа хурууны хээгээр нэвтрэхийг идэвхжүүлэх үү?',
                style: TextStyle(fontSize: 14, color: c.primary,
                    height: 1.4)),
              const SizedBox(height: 8),
              Text(
                'Та дараа нь Профайл → Хурууны хээ дээрээс өөрчлөх боломжтой.',
                style: TextStyle(fontSize: 12,
                    color: c.mutedForeground, height: 1.3)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Үгүй',
                  style: TextStyle(color: c.mutedForeground)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.fingerprint, size: 18),
              label: const Text('Идэвхжүүлэх'),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.brandGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _bio.setEnabled(true);
    } else {
      await _bio.setEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: Stack(children: [
        // ── Green wave ──
        ClipPath(
          clipper: _WaveClipper(),
          child: Container(
            height: h * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.brandGreen,
                  const Color(0xFF047857),
                  const Color(0xFF065F46),
                ],
              ),
            ),
          ),
        ),
        // ── Content ──
        SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              SizedBox(height: h * 0.06),
              Image.asset('assets/images/zev_logo.png', height: 90),
              const SizedBox(height: 12),
              const Text('Цэвэрлэгээний апп',
                  style: TextStyle(fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              const Text(
                  'Цэвэрлэгчид даалгавруудаа харах болон удирдах',
                  style: TextStyle(fontSize: 15,
                      color: Colors.white70)),
              SizedBox(height: h * 0.08),
              // ── Form card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                    boxShadow: [BoxShadow(
                      color: c.primary.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Нэвтрэх',
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: c.primary)),
                        const SizedBox(height: 4),
                        Text('Бүртгэлтэй мэдээллээ оруулна уу',
                            style: TextStyle(fontSize: 15,
                                color: c.mutedForeground)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailCtrl,
                          style: TextStyle(color: c.primary, fontSize: 16),
                          decoration: _inputDeco(c, 'Имэйл / ID',
                              Icons.person_outline),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'ID-гаа оруулна уу' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          style: TextStyle(color: c.primary, fontSize: 16),
                          decoration: _inputDeco(c, 'Нууц үг',
                              Icons.lock_outline),
                          obscureText: true,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Нууц үгээ оруулна уу' : null,
                        ),
                        const SizedBox(height: 24),

                        // ── Login + Fingerprint row ──
                        Row(children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.brandGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                elevation: 0),
                              child: _isLoading
                                  ? const SizedBox(width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                                  Colors.white)))
                                  : const Text('Нэвтрэх',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          // ── Fingerprint button ──
                          if (_bioSupported && _bioEnabled) ...[
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: c.brandGreen.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: c.brandGreen
                                        .withOpacity(0.2))),
                              child: IconButton(
                                onPressed: _handleBiometricLogin,
                                icon: Icon(Icons.fingerprint,
                                    color: c.brandGreen, size: 28),
                                tooltip: 'Хурууны хээ',
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  InputDecoration _inputDeco(
      AppColorScheme c, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.mutedForeground),
      prefixIcon: Icon(icon, color: c.mutedForeground),
      filled: true,
      fillColor: c.muted,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.inputBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.inputBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.brandGreen, width: 2)),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()..lineTo(0, size.height * 0.75);
    p.quadraticBezierTo(size.width * 0.25, size.height,
        size.width * 0.5, size.height * 0.85);
    p.quadraticBezierTo(size.width * 0.75, size.height * 0.7,
        size.width, size.height * 0.85);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
