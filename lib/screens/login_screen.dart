import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});
  final VoidCallback onLoggedIn;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  final _bio = BiometricService();
  bool _bioSupported = false;
  bool _bioEnabled = false;
  String _appVersion = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    _initBiometric();
    _loadVersion();
  }

  Future<void> _initBiometric() async {
    final supported = await _bio.isDeviceSupported();
    final enabled = await _bio.isEnabled();
    // Check if there's a saved session (user previously logged in via API)
    final hasSession = await AuthService.restoreSession();
    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = enabled && hasSession; // only enable if saved session exists
    });
    if (_bioSupported && _bioEnabled) _handleBiometricLogin();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _isLoading = false);
      await _maybeAskBiometric();
      if (!mounted) return;
      widget.onLoggedIn();
    } else {
      setState(() {
        _isLoading = false;
      });
      AppToast.show(
        context, 
        result.errorMessage ?? 'Алдаа гарлаа',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_bioSupported || !_bioEnabled) return;
    // Only allow biometric if we have a valid saved session
    if (!AuthService.isLoggedIn) return;
    final authenticated = await _bio.authenticate();
    if (authenticated && mounted) widget.onLoggedIn();
  }

  void _showForgotPassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordModal(),
    );
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
              child: Icon(Platform.isIOS ? Icons.face_unlock_rounded : Icons.fingerprint,
                  color: c.brandGreen, size: 28)),
            const SizedBox(width: 12),
            Expanded(child: Text(Platform.isIOS ? 'Face ID' : 'Хурууны хээ',
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: c.primary))),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Platform.isIOS 
                  ? 'Дараагийн удаа Face ID-аар нэвтрэхийг идэвхжүүлэх үү?'
                  : 'Дараагийн удаа хурууны хээгээр нэвтрэхийг идэвхжүүлэх үү?',
                style: TextStyle(fontSize: 14, color: c.primary,
                    height: 1.4)),
              const SizedBox(height: 8),
              Text(
                Platform.isIOS
                  ? 'Та дараа нь Профайл → Face ID дээрээс өөрчлөх боломжтой.'
                  : 'Та дараа нь Профайл → Хурууны хээ дээрээс өөрчлөх боломжтой.',
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
              icon: Icon(Platform.isIOS ? Icons.face_unlock_rounded : Icons.fingerprint, size: 18),
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
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTablet = size.shortestSide > 600;
    final isShortScreen = size.height < 750; // Increased threshold for iPhone 11 compact feel
    final maxFormWidth = isTablet ? 480.0 : 380.0; // Slightly smaller max width for mobile
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: c.loginBackground,
      body: Stack(children: [
        // ── Background gradient with decorative circles ──
        Positioned.fill(
          child: CustomPaint(
            painter: _BgPainter(c: c),
          ),
        ),

        // ── Main content ──
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isLandscape) {
                // ── Landscape: Side-by-side ──
                return Row(children: [
                  // Left: branding
                  Expanded(
                    flex: 4,
                    child: _buildBranding(c, isCompact: true),
                  ),
                  // Right: form
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildFormCard(c, maxFormWidth),
                      ),
                    ),
                  ),
                ]);
              }

              // ── Portrait ──
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isTablet ? 40 : (isShortScreen ? 12 : 20)),
                      _buildBranding(c, isCompact: false, isShort: isShortScreen),
                      SizedBox(height: isTablet ? 40 : (isShortScreen ? 16 : 24)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 60 : 12),
                        child: _buildFormCard(c, maxFormWidth, isShort: isShortScreen),
                      ),
                      const SizedBox(height: 16),
                      // Footer
                      Text('© ${DateTime.now().year} Zevtabs LLC',
                          style: TextStyle(fontSize: 11,
                              color: c.mutedForeground.withOpacity(0.5))),
                      if (_appVersion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('v$_appVersion',
                            style: TextStyle(fontSize: 10,
                                color: c.mutedForeground.withOpacity(0.35))),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════
  //  Branding Section
  // ══════════════════════════════════════════
  Widget _buildBranding(AppColorScheme c, {required bool isCompact, bool isShort = false}) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo container with glow
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: c.brandGreen.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset('assets/images/zev_logo.png',
                height: isCompact ? 48 : (isShort ? 56 : 64)),
          ),
          const SizedBox(height: 10),
          Text('Цэвэрлэгээний апп',
              style: TextStyle(
                fontSize: isCompact ? 18 : (isShort ? 22 : 24),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 6),
          Text(
            'Даалгавруудаа удирдаж, хянаж ажиллана уу',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCompact ? 12 : (isShort ? 12 : 13),
              color: Colors.white.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  Form Card
  // ══════════════════════════════════════════
  Widget _buildFormCard(AppColorScheme c, double maxWidth, {bool isShort = false}) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: EdgeInsets.all(isShort ? 16 : 20),
              decoration: BoxDecoration(
                color: c.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.login_rounded,
                            color: c.brandGreen, size: isShort ? 18 : 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Нэвтрэх',
                              style: TextStyle(
                                fontSize: isShort ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: c.primary,
                              ),
                            ),
                            Text(
                              'Бүртгэлтэй мэдээллээ оруулна уу',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ]),
                    SizedBox(height: isShort ? 16 : 24),

                    // Username field
                    Text('Нэвтрэх нэр', style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      style: TextStyle(color: c.primary, fontSize: 16),
                      textInputAction: TextInputAction.next,
                      decoration: _inputDeco(c, 'Нэвтрэх нэрээ оруулна уу',
                          Icons.person_outline),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Нэвтрэх нэрээ оруулна уу' : null,
                    ),
                    SizedBox(height: isShort ? 14 : 18),

                    // Password field
                    Text('Нууц үг', style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passCtrl,
                      style: TextStyle(color: c.primary, fontSize: 16),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: _inputDeco(c, 'Нууц үг оруулна уу',
                          Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: c.mutedForeground, size: 20),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Нууц үгээ оруулна уу' : null,
                    ),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPassword(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text('Нууц үг мартсан?',
                            style: TextStyle(fontSize: 13,
                                color: c.brandGreen,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    SizedBox(height: isShort ? 12 : 16),

                    // ── Login button ──
                    SizedBox(
                      width: double.infinity,
                      height: isShort ? 48 : 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.brandGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white)))
                            : const Text('Нэвтрэх',
                                style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),

                    // ── Biometric section ──
                    if (_bioSupported && _bioEnabled) ...[
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: Divider(color: c.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('эсвэл',
                              style: TextStyle(fontSize: 13,
                                  color: c.mutedForeground)),
                        ),
                        Expanded(child: Divider(color: c.border)),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: isShort ? 44 : 48,
                        child: OutlinedButton(
                          onPressed: _handleBiometricLogin,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: c.brandGreen.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Platform.isIOS ? Icons.face_unlock_rounded : Icons.fingerprint,
                                  color: c.brandGreen, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  Platform.isIOS ? 'Face ID-аар нэвтрэх' : 'Хурууны хээгээр нэвтрэх',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: c.brandGreen),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
      AppColorScheme c, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.mutedForeground.withOpacity(0.6),
          fontSize: 14),
      prefixIcon: Icon(icon, color: c.mutedForeground, size: 20),
      filled: true,
      fillColor: c.muted,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.inputBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.inputBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.brandGreen, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.destructive)),
    );
  }
}

// ══════════════════════════════════════════
//  Background Painter with gradient + circles
// ══════════════════════════════════════════
class _BgPainter extends CustomPainter {
  _BgPainter({required this.c});
  final AppColorScheme c;

  @override
  void paint(Canvas canvas, Size size) {
    // Main gradient bg
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          c.brandGreen,
          c.brandGreen.withOpacity(0.85),
          c.loginBackground,
          c.loginBackground,
        ],
        stops: const [0.0, 0.35, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Decorative circles
    final circlePaint = Paint()..color = Colors.white.withOpacity(0.05);

    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.08),
        size.width * 0.35, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.22),
        size.width * 0.25, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.3),
        size.width * 0.15, circlePaint);

    // Wave separator
    final wavePaint = Paint()..color = c.loginBackground;
    final wavePath = Path();
    final waveY = size.height * 0.38;
    wavePath.moveTo(0, waveY);
    wavePath.quadraticBezierTo(
        size.width * 0.25, waveY + 30,
        size.width * 0.5, waveY - 10);
    wavePath.quadraticBezierTo(
        size.width * 0.75, waveY - 50,
        size.width, waveY + 10);
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════
//  Forgot Password Modal (Multi-step)
// ══════════════════════════════════════════
class _ForgotPasswordModal extends StatefulWidget {
  const _ForgotPasswordModal();
  @override
  State<_ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<_ForgotPasswordModal> {
  int _step = 0; // 0=email, 1=code, 2=new password, 3=success
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocuses = List.generate(6, (_) => FocusNode());
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _codeControllers) { c.dispose(); }
    for (final f in _codeFocuses) { f.dispose(); }
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() { _loading = false; _step = 1; });
    // Auto-focus first code field
    _codeFocuses[0].requestFocus();
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length < 6) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() { _loading = false; _step = 2; });
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.isEmpty || _newPassCtrl.text.length < 6) return;
    if (_newPassCtrl.text != _confirmPassCtrl.text) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() { _loading = false; _step = 3; });
  }

  int _passwordStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) score++;
    return score.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: c.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            // Step indicator
            if (_step < 3) ...[
              Row(children: List.generate(3, (i) {
                final isActive = i <= _step;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isActive ? c.brandGreen : c.muted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              })),
              const SizedBox(height: 20),
            ],

            // Steps
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _buildStep(c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(AppColorScheme c) {
    switch (_step) {
      case 0: return _stepEmail(c);
      case 1: return _stepCode(c);
      case 2: return _stepNewPassword(c);
      case 3: return _stepSuccess(c);
      default: return const SizedBox.shrink();
    }
  }

  // ── Step 0: Enter Email ──
  Widget _stepEmail(AppColorScheme c) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.brandGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.email_outlined, color: c.brandGreen, size: 28),
        ),
        const SizedBox(height: 14),
        Text('Нууц үг сэргээх',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: c.primary)),
        const SizedBox(height: 6),
        Text('Бүртгэлтэй имэйл хаяг эсвэл ID оруулна уу. '
            'Бид таньд баталгаажуулах код илгээх болно.',
            style: TextStyle(fontSize: 14, color: c.mutedForeground,
                height: 1.4)),
        const SizedBox(height: 20),
        TextField(
          controller: _emailCtrl,
          style: TextStyle(color: c.primary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Имэйл хаяг / ID',
            hintStyle: TextStyle(color: c.mutedForeground.withOpacity(0.6)),
            prefixIcon: Icon(Icons.person_outline,
                color: c.mutedForeground, size: 20),
            filled: true, fillColor: c.muted,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.inputBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.inputBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.brandGreen, width: 2)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0),
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Код илгээх',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step 1: Enter Code ──
  Widget _stepCode(AppColorScheme c) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.sms_outlined, color: c.info, size: 28),
        ),
        const SizedBox(height: 14),
        Text('Код баталгаажуулах',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: c.primary)),
        const SizedBox(height: 6),
        RichText(text: TextSpan(
          style: TextStyle(fontSize: 14, color: c.mutedForeground,
              height: 1.4),
          children: [
            const TextSpan(text: 'Бид '),
            TextSpan(text: _emailCtrl.text,
                style: TextStyle(color: c.primary,
                    fontWeight: FontWeight.w600)),
            const TextSpan(text: ' рүү 6 оронтой код илгээлээ.'),
          ],
        )),
        const SizedBox(height: 24),
        // 6-digit code fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46, height: 54,
              child: TextField(
                controller: _codeControllers[i],
                focusNode: _codeFocuses[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: c.primary),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true, fillColor: c.muted,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.inputBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.inputBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: c.brandGreen, width: 2)),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    _codeFocuses[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    _codeFocuses[i - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Resend
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Код ирээгүй юу? ',
              style: TextStyle(fontSize: 13, color: c.mutedForeground)),
          GestureDetector(
            onTap: () {
              for (final ctrl in _codeControllers) { ctrl.clear(); }
              _codeFocuses[0].requestFocus();
            },
            child: Text('Дахин илгээх',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, color: c.brandGreen)),
          ),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0),
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Баталгаажуулах',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step 2: New Password ──
  Widget _stepNewPassword(AppColorScheme c) {
    final strength = _passwordStrength(_newPassCtrl.text);
    final strengthLabels = ['', 'Маш сул', 'Сул', 'Дунд', 'Сайн', 'Маш сайн'];
    final strengthColors = [
      c.border, c.destructive, c.warningOrange,
      c.warningOrange, c.success, c.brandGreen,
    ];
    final passwordsMatch = _newPassCtrl.text.isNotEmpty &&
        _newPassCtrl.text == _confirmPassCtrl.text;

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.brandGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.lock_reset_rounded,
              color: c.brandGreen, size: 28),
        ),
        const SizedBox(height: 14),
        Text('Шинэ нууц үг',
            style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: c.primary)),
        const SizedBox(height: 6),
        Text('6-аас дээш тэмдэгт бүхий шинэ нууц үгээ оруулна уу.',
            style: TextStyle(fontSize: 14, color: c.mutedForeground,
                height: 1.4)),
        const SizedBox(height: 20),
        // New password
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.primary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Шинэ нууц үг',
            hintStyle: TextStyle(
                color: c.mutedForeground.withOpacity(0.6)),
            prefixIcon: Icon(Icons.lock_outline,
                color: c.mutedForeground, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                  color: c.mutedForeground, size: 20),
              onPressed: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),
            filled: true, fillColor: c.muted,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.inputBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.inputBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.brandGreen, width: 2)),
          ),
        ),
        // Strength indicator
        if (_newPassCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            ...List.generate(5, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < strength
                      ? strengthColors[strength]
                      : c.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
            const SizedBox(width: 8),
            Text(strengthLabels[strength],
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: strengthColors[strength])),
          ]),
        ],
        const SizedBox(height: 14),
        // Confirm password
        TextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: c.primary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Нууц үг давтах',
            hintStyle: TextStyle(
                color: c.mutedForeground.withOpacity(0.6)),
            prefixIcon: Icon(Icons.lock_outline,
                color: c.mutedForeground, size: 20),
            suffixIcon: _confirmPassCtrl.text.isNotEmpty
                ? Icon(
                    passwordsMatch
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: passwordsMatch ? c.success : c.destructive,
                    size: 22)
                : null,
            filled: true, fillColor: c.muted,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.inputBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: _confirmPassCtrl.text.isNotEmpty && !passwordsMatch
                        ? c.destructive : c.inputBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.brandGreen, width: 2)),
          ),
        ),
        if (_confirmPassCtrl.text.isNotEmpty && !passwordsMatch) ...[
          const SizedBox(height: 6),
          Text('Нууц үг таарахгүй байна',
              style: TextStyle(fontSize: 12, color: c.destructive)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _loading || !passwordsMatch
                || _newPassCtrl.text.length < 6 ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: c.muted,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0),
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Нууц үг шинэчлэх',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step 3: Success ──
  Widget _stepSuccess(AppColorScheme c) {
    return Column(
      key: const ValueKey(3),
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.success.withOpacity(0.1),
          ),
          child: Icon(Icons.check_circle_rounded,
              color: c.success, size: 56),
        ),
        const SizedBox(height: 20),
        Text('Амжилттай!',
            style: TextStyle(fontSize: 24,
                fontWeight: FontWeight.bold, color: c.primary)),
        const SizedBox(height: 8),
        Text('Таны нууц үг амжилттай шинэчлэгдлээ.\n'
            'Шинэ нууц үгээрээ нэвтэрнэ үү.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14,
                color: c.mutedForeground, height: 1.5)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0),
            child: const Text('Нэвтрэх хуудас руу буцах',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
