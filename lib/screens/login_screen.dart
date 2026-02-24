import 'package:flutter/material.dart';

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
    widget.onLoggedIn();
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
              Text('Цэвэрлэгээний апп',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                      color: c.primaryForeground)),
              const SizedBox(height: 4),
              Text('Цэвэрлэгчид даалгавруудаа харах болон удирдах',
                  style: TextStyle(fontSize: 13,
                      color: c.primaryForeground.withOpacity(0.8))),
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
                      blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Нэвтрэх', style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold, color: c.primary)),
                        const SizedBox(height: 4),
                        Text('Бүртгэлтэй мэдээллээ оруулна уу',
                            style: TextStyle(fontSize: 13,
                                color: c.mutedForeground)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailCtrl,
                          style: TextStyle(color: c.primary),
                          decoration: _inputDeco(c, 'Имэйл / ID',
                              Icons.person_outline),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'ID-гаа оруулна уу' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          style: TextStyle(color: c.primary),
                          decoration: _inputDeco(c, 'Нууц үг',
                              Icons.lock_outline),
                          obscureText: true,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Нууц үгээ оруулна уу' : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.brandGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation(Colors.white)))
                                : const Text('Нэвтрэх',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
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

  InputDecoration _inputDeco(AppColorScheme c, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.mutedForeground),
      prefixIcon: Icon(icon, color: c.mutedForeground),
      filled: true,
      fillColor: c.muted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.inputBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.inputBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
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
    p.lineTo(size.width, 0); p.close();
    return p;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
