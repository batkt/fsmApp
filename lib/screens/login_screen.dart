import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/forgot_password_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

/// Custom formatter for PIN code that handles paste operations correctly
class PinCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract only digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 4 digits
    final limited = digitsOnly.length > 4
        ? digitsOnly.substring(0, 4)
        : digitsOnly;

    // Calculate new selection position
    final selectionOffset = limited.length;

    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }
}

/// Custom formatter for OTP code fields that handles paste/autofill operations
class OTPCodeFormatter extends TextInputFormatter {
  final Function(String)? onPaste;

  OTPCodeFormatter({this.onPaste});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract only digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // If multiple digits detected (paste/autofill), trigger callback
    if (digitsOnly.length > 1 && onPaste != null) {
      onPaste!(digitsOnly);
      // Return empty to prevent filling the first field
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Limit to 1 digit for normal input
    final limited = digitsOnly.length > 1
        ? digitsOnly.substring(0, 1)
        : digitsOnly;

    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});
  final VoidCallback onLoggedIn;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pinFocus = FocusNode();
  bool _isLoading = false;
  final bool _obscure = true;
  bool _rememberMe = true;
  final _bio = BiometricService();
  bool _bioSupported = false;
  bool _bioEnabled = false;
  String _appVersion = '';

  /// Нээгдэх үеийн нэг удаагийн хөдөлгөөн (sheet дээш гулсах, гарчиг гарах)
  late AnimationController _animCtrl;
  /// Hero зургийн тасралтгүй давталт (араа, утас, даалгаврын чагт)
  late AnimationController _loopCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _initBiometric();
    _loadVersion();
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final saved = await AuthService.getSavedUsername();
    final rememberMe = await AuthService.isRememberMeEnabled();
    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        if (saved != null && _emailCtrl.text.isEmpty) {
          _emailCtrl.text = saved;
        }
      });
    }
  }

  Future<void> _initBiometric() async {
    final supported = await _bio.isDeviceSupported();
    final enabled = await _bio.isEnabled();
    // Check if there's a saved session that can be restored via Biometrics
    final hasSession = await AuthService.restoreBiometricSession();
    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled =
          enabled && hasSession; // only enable if saved session exists
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _loopCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    FocusScope.of(context).unfocus();
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
      await AuthService.saveRememberedUsername(
        _emailCtrl.text.trim(),
        _rememberMe,
      );
      await _maybeAskBiometric();
      if (!mounted) return;
      widget.onLoggedIn();
    } else {
      setState(() {
        _isLoading = false;
        _passCtrl.clear();
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
    if (!_bioSupported) return;

    if (!_bioEnabled) {
      AppToast.show(
        context,
        Platform.isIOS
            ? 'Face ID идэвхжүүлэхийн тулд эхлээд нэг удаа нэвтрэх шаардлагатай'
            : 'Хурууны хээ идэвхжүүлэхийн тулд эхлээд нэг удаа нэвтрэх шаардлагатай',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authenticated = await _bio.authenticate();
      if (authenticated && mounted) {
        // Check if we have a valid session after authentication
        final hasSession = await AuthService.restoreBiometricSession();
        if (hasSession && mounted) {
          widget.onLoggedIn();
          return;
        } else {
          if (mounted) {
            AppToast.show(context, 'Сэсси хугацаа дууссан байна. Нууц кодоор нэвтэрнэ үү.');
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? Icons.face_unlock_rounded
                    : Icons.fingerprint,
                color: c.brandGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  defaultTargetPlatform == TargetPlatform.iOS
                      ? 'Face ID'
                      : 'Хурууны хээ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? 'Дараагийн удаа Face ID-аар нэвтрэхийг идэвхжүүлэх үү?'
                    : 'Дараагийн удаа хурууны хээгээр нэвтрэхийг идэвхжүүлэх үү?',
                style: TextStyle(fontSize: 14, color: c.primary, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? 'Та дараа нь Профайл → Face ID дээрээс өөрчлөх боломжтой.'
                    : 'Та дараа нь Профайл → Хурууны хээ дээрээс өөрчлөх боломжтой.',
                style: TextStyle(
                  fontSize: 12,
                  color: c.mutedForeground,
                  height: 1.3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Үгүй', style: TextStyle(color: c.mutedForeground)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: c.brandGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Идэвхжүүлэх'),
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

  bool get _khudulguunKhasakh => MediaQuery.of(context).disableAnimations;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_khudulguunKhasakh) {
      _loopCtrl.stop();
      _animCtrl.value = 1;
    } else if (!_loopCtrl.isAnimating) {
      _loopCtrl.repeat();
    }
    return Scaffold(
      backgroundColor: _heroUngu,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(builder: (context, box) {
        final urgun = box.maxWidth >= 720 || box.maxWidth > box.maxHeight * 1.3;
        if (urgun) {
          // iPad, Galaxy Fold (дэлгэж), хэвтээ утас: hero зүүн, форм баруун
          return Row(children: [
            Expanded(
              flex: 5,
              child: _Hero(
                loop: _loopCtrl,
                intro: _animCtrl,
                compact: box.maxHeight < 520,
                deedZai: MediaQuery.paddingOf(context).top,
                zuunZai: MediaQuery.paddingOf(context).left,
              ),
            ),
            Expanded(
              flex: 6,
              child: _SheetSlide(
                intro: _animCtrl,
                fromRight: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(36)),
                  ),
                  child: SafeArea(
                    left: false,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildForm(c),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }

        // Утас босоо: hero дээр, цагаан sheet доороос гулсаж гарна
        final deed = MediaQuery.paddingOf(context).top;
        final dood = MediaQuery.paddingOf(context).bottom;
        // Формд хэрэгтэй өндрийг (хувилбарын мөр хүртэл) эхэлж өгөөд үлдсэнийг hero авна
        final formKheregtei = 500.0 + dood;
        final heroH = (box.maxHeight - formKheregtei + 32).clamp(210.0, 380.0);
        return Stack(children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroH,
            // Hero статус мөрийн доор хүртэл үргэлжилнэ
            child: _Hero(loop: _loopCtrl, intro: _animCtrl, compact: false, deedZai: deed),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(top: heroH - 32),
            child: _SheetSlide(
                intro: _animCtrl,
                child: Container(
                  constraints: BoxConstraints(minHeight: box.maxHeight - heroH + 32),
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    box.maxWidth < 360 ? 20 : 28,
                    28,
                    box.maxWidth < 360 ? 20 : 28,
                    16 + dood,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _buildForm(c),
                    ),
                  ),
                ),
              ),
          ),
        ]);
      }),
    );
  }

  Widget _buildForm(AppColorScheme c) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Нэвтрэх',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.8, color: c.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Ажлын бүртгэлээрээ нэвтэрнэ үү',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.mutedForeground),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _emailCtrl,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: TextStyle(color: c.primary, fontSize: 16),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              onFieldSubmitted: (_) => _pinFocus.requestFocus(),
              decoration: _pillDeco(c, 'Нэвтрэх нэр', Icons.person_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Нэвтрэх нэрээ оруулна уу' : null,
            ),
            const SizedBox(height: 14),
            FormField<String>(
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              validator: (_) {
                final v = _passCtrl.text;
                if (v.isEmpty) return 'Нууц кодыг оруулна уу';
                if (v.length != 4) return 'Нууц код 4 оронтой байх ёстой';
                return null;
              },
              builder: (field) => _PinKhairtsag(
                controller: _passCtrl,
                focusNode: _pinFocus,
                obscure: _obscure,
                aldaa: field.errorText,
                idevkhteiUngu: _heroUngu,
                onSubmitted: _handleLogin,
                onChanged: (v) {
                  field.didChange(v);
                  // 4 орон бүрэн, нэр бөглөгдсөн бол шууд нэвтэрнэ
                  if (v.length == 4 && _emailCtrl.text.trim().isNotEmpty) _handleLogin();
                },
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 2,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          activeColor: _heroUngu,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          side: BorderSide(color: c.mutedForeground.withValues(alpha: 0.5), width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Намайг сана', style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                    ]),
                  ),
                ),
                TextButton(
                  onPressed: () => _showForgotPassword(context),
                  style: TextButton.styleFrom(
                    foregroundColor: c.brandGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Нууц код мартсан?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: _heroUngu,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _heroUngu.withValues(alpha: 0.6),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isLoading
                          ? const SizedBox(
                              key: ValueKey('ach'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Нэвтрэх', key: ValueKey('txt')),
                    ),
                  ),
                ),
              ),
              // Face ID / хурууны хээ — нэвтрэх товчны хажууд дугуй товч
              if (_bioSupported) ...[
                const SizedBox(width: 12),
                Tooltip(
                  message: ios ? 'Face ID-аар нэвтрэх' : 'Хурууны хээгээр нэвтрэх',
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: _heroUngu,
                        side: const BorderSide(color: _heroUngu, width: 1.5),
                        shape: const CircleBorder(),
                      ),
                      child: Icon(ios ? Icons.face_unlock_rounded : Icons.fingerprint, size: 26),
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 18),
            Text(
              _appVersion.isEmpty
                  ? '© ${DateTime.now().year} Zevtabs LLC'
                  : '© ${DateTime.now().year} Zevtabs LLC, v$_appVersion',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.mutedForeground.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _pillDeco(AppColorScheme c, String hint, IconData icon) {
    OutlineInputBorder border(Color color, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide(color: color, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: c.mutedForeground.withValues(alpha: 0.8), fontSize: 15),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Icon(icon, color: c.mutedForeground, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0),
      filled: true,
      fillColor: c.muted,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_heroUngu, 2),
      errorBorder: border(c.destructive),
      focusedErrorBorder: border(c.destructive, 2),
      errorStyle: const TextStyle(height: 1.2),
    );
  }
}

const _heroUngu = Color(0xFF0E9F7A);
const _heroGeree = Color(0xFF9FF3D6);

/// Нээгдэхэд доороос (эсвэл баруунаас) гулсаж гарах
class _SheetSlide extends StatelessWidget {
  const _SheetSlide({required this.intro, required this.child, this.fromRight = false});
  final Animation<double> intro;
  final Widget child;
  final bool fromRight;
  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: intro, curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: a,
      builder: (context, ch) => FractionalTranslation(
        translation: fromRight ? Offset(0.25 * (1 - a.value), 0) : Offset(0, 0.35 * (1 - a.value)),
        child: Opacity(opacity: a.value.clamp(0, 1), child: ch),
      ),
      child: child,
    );
  }
}

/// Hero-д ээлжлэн харагдах модуль. Шинэ модуль нэмэхдээ [_heroModuluud]-д нэг мөр нэмнэ.
class _HeroModul {
  const _HeroModul({
    required this.ner,
    required this.tuvgerUg,
    required this.uldsen,
    required this.ungu,
    required this.zurag,
  });
  final String ner;
  /// Гарчгийн тодруулсан эхний үг
  final String tuvgerUg;
  final String uldsen;
  /// Арын градиентийн гол өнгө
  final Color ungu;
  /// (өргөн, өндөр, модуль доторх явц 0..1, бүх давталтын явц 0..1)
  final Widget Function(double w, double h, double yavts, double t) zurag;
}

final _heroModuluud = <_HeroModul>[
  _HeroModul(
    ner: 'FSM',
    tuvgerUg: 'Даалгавраа',
    uldsen: ' нэг дор хяна.',
    ungu: _heroUngu,
    zurag: (w, h, yavts, t) => _FsmZurag(w: w, h: h, yavts: yavts, t: t),
  ),
  _HeroModul(
    ner: 'Ирц',
    tuvgerUg: 'Ирцээ',
    uldsen: ' нэг товчоор бүртгэ.',
    ungu: const Color(0xFF0D9488),
    zurag: (w, h, yavts, t) => _IrtsZurag(w: w, h: h, yavts: yavts),
  ),
  _HeroModul(
    ner: 'Цалин',
    tuvgerUg: 'Цалингаа',
    uldsen: ' цаг алдалгүй хар.',
    ungu: const Color(0xFF047857),
    zurag: (w, h, yavts, t) => _TsalinZurag(w: w, h: h, yavts: yavts),
  ),
];

/// Дээд ногоон хэсэг: модуль бүрийн гарчиг + хөдөлгөөнт зураг ээлжлэн солигдоно
class _Hero extends StatelessWidget {
  const _Hero({
    required this.loop,
    required this.intro,
    required this.compact,
    this.deedZai = 0,
    this.zuunZai = 0,
  });
  final Animation<double> loop;
  final Animation<double> intro;
  final bool compact;
  final double deedZai;
  final double zuunZai;

  @override
  Widget build(BuildContext context) {
    final n = _heroModuluud.length;
    return AnimatedBuilder(
      animation: Listenable.merge([loop, intro]),
      builder: (context, _) {
        final bairlal = loop.value * n;
        final idx = bairlal.floor() % n;
        final yavts = bairlal - bairlal.floor();
        final modul = _heroModuluud[idx];
        final introA = CurvedAnimation(parent: intro, curve: const Interval(0, 0.6, curve: Curves.easeOut)).value;

        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: modul.ungu),
          duration: const Duration(milliseconds: 700),
          builder: (context, ungu, child) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.2),
                radius: 1.3,
                colors: [
                  Color.lerp(ungu, Colors.white, 0.18)!,
                  ungu!,
                  Color.lerp(ungu, Colors.black, 0.22)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: child,
          ),
          child: Padding(
            padding: EdgeInsets.only(top: deedZai, left: zuunZai),
            child: LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth;
              final h = box.maxHeight;
              final garchigFont = compact ? 24.0 : (w < 360 ? 27.0 : 32.0);
              final garchigDeed = compact ? 16.0 : 24.0;
              // Зураг гарчгийн доорх зайд багтана
              final zuragDeed = garchigDeed + 2 * garchigFont * 1.15 + 8;
              return Stack(clipBehavior: Clip.hardEdge, children: [
                // Гогцоо зураас (бүх модульд нийтлэг)
                Positioned(
                  right: -20,
                  top: 0,
                  width: w * 0.5,
                  height: h * 0.45,
                  child: CustomPaint(
                    painter: _GogtsooPainter(
                      zurakh: CurvedAnimation(parent: intro, curve: Curves.easeInOut).value,
                      shiljilt: loop.value,
                    ),
                  ),
                ),
                // Модулийн зураг — солигдохдоо уусч орно
                Positioned(
                  left: 0,
                  right: 0,
                  top: zuragDeed,
                  bottom: 0,
                  child: Opacity(
                    opacity: CurvedAnimation(parent: intro, curve: const Interval(0.3, 1)).value,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 550),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (ch, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(a), child: ch),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(modul.ner),
                        child: LayoutBuilder(
                          builder: (context, zb) => modul.zurag(zb.maxWidth, zb.maxHeight, yavts, loop.value),
                        ),
                      ),
                    ),
                  ),
                ),
                // Гарчиг
                Positioned(
                  left: compact ? 24 : 28,
                  right: w * 0.1,
                  top: garchigDeed,
                  child: Opacity(
                    opacity: introA,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - introA)),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, ?cur]),
                        transitionBuilder: (ch, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
                            child: ch,
                          ),
                        ),
                        child: Text.rich(
                          key: ValueKey(modul.ner),
                          TextSpan(children: [
                            TextSpan(text: modul.tuvgerUg, style: const TextStyle(color: _heroGeree)),
                            TextSpan(text: modul.uldsen),
                          ]),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: garchigFont,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]);
            }),
          ),
        );
      },
    );
  }
}

/// FSM: эргэх араа + даалгавар чагтлагдах утас
class _FsmZurag extends StatelessWidget {
  const _FsmZurag({required this.w, required this.h, required this.yavts, required this.t});
  final double w, h, yavts, t;
  @override
  Widget build(BuildContext context) {
    final gTom = (math.min(w, h) * 0.62).clamp(60.0, 170.0);
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: w * 0.06,
        bottom: h * 0.08,
        child: SizedBox(
          width: gTom * 1.6,
          height: gTom * 1.4,
          child: Stack(children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: t * 2 * math.pi * 2,
                child: CustomPaint(size: Size.square(gTom), painter: _AraaPainter(shud: 10)),
              ),
            ),
            Positioned(
              left: gTom * 0.78,
              top: 0,
              child: Transform.rotate(
                angle: -t * 2 * math.pi * 2 * 10 / 7 + 0.2,
                child: CustomPaint(size: Size.square(gTom * 0.68), painter: _AraaPainter(shud: 7)),
              ),
            ),
          ]),
        ),
      ),
      Positioned(
        right: -w * 0.08,
        top: h * 0.02 + math.sin(t * 2 * math.pi * 3) * 6,
        child: _MiniUtas(
          urgun: (w * 0.46).clamp(140.0, 260.0),
          undur: (h * 1.0).clamp(120.0, 320.0),
          t: yavts,
        ),
      ),
    ]);
  }
}

/// Ирц: том хурууны хээ импульстэй + ирсэн/явсан цагийн чипүүд
class _IrtsZurag extends StatelessWidget {
  const _IrtsZurag({required this.w, required this.h, required this.yavts});
  final double w, h, yavts;
  @override
  Widget build(BuildContext context) {
    final r = (math.min(w, h) * 0.42).clamp(44.0, 110.0);
    final p = (yavts * 2) % 1; // 2 импульс
    final yawsanKharagdakh = yavts > 0.5;
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: w * (w < 380 ? 0.06 : 0.12),
        top: (h - r * 2) / 2,
        width: r * 2,
        height: r * 2,
        child: Stack(alignment: Alignment.center, children: [
          for (final k in [0.0, 0.5])
            Builder(builder: (_) {
              final q = (p + k) % 1;
              return Container(
                width: r * 2 * (0.55 + q * 0.45),
                height: r * 2 * (0.55 + q * 0.45),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5 * (1 - q)), width: 2),
                ),
              );
            }),
          Container(
            width: r * 1.1,
            height: r * 1.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Icon(Icons.fingerprint_rounded, size: r * 0.75, color: const Color(0xFF0D9488)),
          ),
        ]),
      ),
      Positioned(
        // Чипүүд баруун захаас — нарийн дэлгэцэд ч бүтэн харагдана
        right: w * 0.05 + 22,
        top: h * 0.18,
        child: const _TsagChip(ner: 'Цагтаа ирлээ', tsag: '08:52', ikon: Icons.verified_rounded),
      ),
      Positioned(
        right: w * 0.05,
        top: h * 0.18 + 56,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: yawsanKharagdakh ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            offset: yawsanKharagdakh ? Offset.zero : const Offset(0, 0.4),
            child: const _TsagChip(ner: 'Ажил дууслаа', tsag: '18:04', ikon: Icons.wb_twilight_rounded),
          ),
        ),
      ),
    ]);
  }
}

class _TsagChip extends StatelessWidget {
  const _TsagChip({required this.ner, required this.tsag, required this.ikon});
  final String ner, tsag;
  final IconData ikon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFCCFBF1)),
          child: Icon(ikon, size: 16, color: const Color(0xFF0D9488)),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(ner, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
          Text(tsag,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontFeatures: [FontFeature.tabularFigures()],
              )),
        ]),
      ]),
    );
  }
}

/// Цалин: дүн нь тоологдож өсөх цалингийн карт + хөвөх зоос
class _TsalinZurag extends StatelessWidget {
  const _TsalinZurag({required this.w, required this.h, required this.yavts});
  final double w, h, yavts;

  static String _mungu(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '₮ $b';
  }

  @override
  Widget build(BuildContext context) {
    final tooloo = Curves.easeOutCubic.transform((yavts / 0.6).clamp(0.0, 1.0));
    final dun = (1850000 * tooloo).round();
    final kartW = (w * 0.56).clamp(170.0, 280.0);
    final kartH = (h * 0.78).clamp(90.0, 150.0);
    return Stack(clipBehavior: Clip.none, children: [
      // Зоосууд
      for (final (dx, dy, r, phase) in [
        (0.08, 0.15, 22.0, 0.0),
        (0.20, 0.55, 15.0, 1.7),
        (0.86, 0.10, 18.0, 3.1),
      ])
        Positioned(
          left: w * dx,
          top: h * dy + math.sin(yavts * 2 * math.pi * 2 + phase) * 6,
          child: Container(
            width: r * 2,
            height: r * 2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFCD34D),
              border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            ),
            child: Text('₮',
                style: TextStyle(fontSize: r * 0.9, fontWeight: FontWeight.w500, color: const Color(0xFFB45309))),
          ),
        ),
      Positioned(
        right: w * 0.06,
        top: (h - kartH) / 2,
        child: Transform.rotate(
          angle: -0.05,
          child: Container(
            width: kartW,
            height: kartH,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF047857)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('11-р сарын цалин',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: tooloo >= 1 ? 1 : 0,
                  child: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                ),
              ]),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_mungu(dun),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                      color: Color(0xFF0F172A),
                      fontFeatures: [FontFeature.tabularFigures()],
                    )),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tooloo,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF10B981),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _AraaPainter extends CustomPainter {
  _AraaPainter({required this.shud});
  final int shud;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rGadna = size.width / 2;
    final rDotor = rGadna * 0.78;
    final path = Path();
    final n = shud * 2;
    for (var i = 0; i <= n * 2; i++) {
      final a = i * math.pi / n;
      final r = (i ~/ 2).isEven ? rGadna : rDotor;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    path.addOval(Rect.fromCircle(center: c, radius: rGadna * 0.34));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _AraaPainter o) => o.shud != shud;
}

class _GogtsooPainter extends CustomPainter {
  _GogtsooPainter({required this.zurakh, required this.shiljilt});
  final double zurakh;
  final double shiljilt;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final dy = math.sin(shiljilt * 2 * math.pi) * 4;
    final path = Path()
      ..moveTo(w * 0.05, h * 0.95 + dy)
      ..cubicTo(w * 0.35, h * 0.7 + dy, w * 0.15, h * 0.25 + dy, w * 0.45, h * 0.3 + dy)
      ..cubicTo(w * 0.75, h * 0.35 + dy, w * 0.7, h * 0.75 + dy, w * 0.5, h * 0.7 + dy)
      ..cubicTo(w * 0.3, h * 0.65 + dy, w * 0.55, h * 0.05 + dy, w * 1.05, h * 0.1 + dy);
    final p = Paint()
      ..color = _heroGeree.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * zurakh), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GogtsooPainter o) => o.zurakh != zurakh || o.shiljilt != shiljilt;
}

/// Hero доторх жижиг утас: даалгаврууд ээлжлэн чагтлагдана
class _MiniUtas extends StatelessWidget {
  const _MiniUtas({required this.urgun, required this.undur, required this.t});
  final double urgun, undur, t;

  static const _daalgavruud = ['Цэвэрлэгээ, 3-р давхар', 'Шил арчих', 'Хог ачих'];

  @override
  Widget build(BuildContext context) {
    // FSM сценийн 4 сек дотор: даалгаврууд ээлжлэн чагтлагдана
    final chagt = (t * 4).floor().clamp(0, 3);
    return Container(
      width: urgun,
      height: undur,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          // Жижиг дэлгэцэд утасны доод хэсэг зүгээр л тасарч харагдана
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('9:41', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
              const Spacer(),
              Container(width: urgun * 0.28, height: 12, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8))),
              const Spacer(),
            ]),
            const SizedBox(height: 10),
            const Text('Өнөөдөр', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            for (var i = 0; i < _daalgavruud.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: i < chagt ? _heroUngu : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: i < chagt ? _heroUngu : const Color(0xFFCBD5E1), width: 1.5),
                    ),
                    child: i < chagt ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _daalgavruud[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: i < chagt ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                        decoration: i < chagt ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
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
  int _step = 0; // 0=phone, 1=code, 2=new password, 3=success
  bool _loading = false;
  final _phoneCtrl = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocuses = List.generate(6, (_) => FocusNode());
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _newPassFocus = FocusNode();
  final _confirmPassFocus = FocusNode();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _resetToken; // Store reset token after OTP verification
  String? _devOtp; // Store OTP for development mode

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocuses) {
      f.dispose();
    }
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _newPassFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      AppToast.show(
        context,
        'Утасны дугаараа оруулна уу',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    // Validate 8 digits
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length != 8) {
      AppToast.show(
        context,
        'Утасны дугаар 8 оронтой байх ёстой',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() => _loading = true);
    final res = await ForgotPasswordService.requestOTP(digitsOnly);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      // Close keyboard after successful phone number input
      FocusScope.of(context).unfocus();

      // In development, OTP might be returned in response
      if (res.data is Map && res.data['otp'] != null) {
        _devOtp = res.data['otp'].toString();
        // Auto-fill OTP in development mode
        if (_devOtp != null && _devOtp!.length == 6) {
          for (int i = 0; i < 6; i++) {
            _codeControllers[i].text = _devOtp![i];
          }
        }
      }

      setState(() => _step = 1);
      _codeFocuses[0].requestFocus();

      AppToast.show(
        context,
        res.data['message'] ?? 'OTP код таны утас руу илгээгдлээ',
        color: context.colors.success,
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      // Backend now consistently returns { success: false, message: "..." }
      // ApiService already extracts message into res.message
      String errorMsg = _translateErrorMessage(res.message ?? 'Алдаа гарлаа');
      AppToast.show(
        context,
        errorMsg,
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _verifyCode() async {
    final phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final code = _codeControllers.map((c) => c.text).join();

    if (code.length < 6) {
      AppToast.show(
        context,
        'OTP кодыг бүрэн оруулна уу',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() => _loading = true);
    final res = await ForgotPasswordService.verifyOTP(phone, code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      // Close keyboard after successful OTP verification
      FocusScope.of(context).unfocus();

      // Store reset token
      if (res.data is Map && res.data['resetToken'] != null) {
        _resetToken = res.data['resetToken'].toString();
        setState(() => _step = 2);
        // Focus first password field when moving to step 2
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _newPassFocus.requestFocus();
          }
        });

        AppToast.show(
          context,
          res.data['message'] ?? 'OTP код баталгаажлаа',
          color: context.colors.success,
          icon: Icons.check_circle_outline_rounded,
        );
      } else {
        // Even if success is true, check for error messages in the response
        String errorMsg = _translateErrorMessage(
          res.data is Map && res.data['message'] != null
              ? res.data['message'].toString()
              : res.message ?? 'OTP буруу байна',
        );
        AppToast.show(
          context,
          errorMsg,
          color: context.colors.destructive,
          icon: Icons.error_outline_rounded,
        );
      }
    } else {
      // Backend now consistently returns { success: false, message: "..." }
      // ApiService already extracts message into res.message
      String errorMsg = _translateErrorMessage(res.message ?? 'Алдаа гарлаа');
      AppToast.show(
        context,
        errorMsg,
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Handle OTP paste/autofill - distribute digits across all 6 fields
  void _handleOTPPaste(String digits) {
    // Extract only digits
    final digitsOnly = digits.replaceAll(RegExp(r'[^0-9]'), '');
    // Limit to 6 digits
    final limited = digitsOnly.length > 6
        ? digitsOnly.substring(0, 6)
        : digitsOnly;

    // Fill all fields
    for (int i = 0; i < 6; i++) {
      if (i < limited.length) {
        _codeControllers[i].text = limited[i];
      } else {
        _codeControllers[i].clear();
      }
    }

    // Move focus to the last filled field or the first empty field
    if (limited.length == 6) {
      _codeFocuses[5].requestFocus();
    } else if (limited.length > 0) {
      _codeFocuses[limited.length].requestFocus();
    }
  }

  /// Translate error messages from backend to user-friendly Mongolian
  String _translateErrorMessage(String msg) {
    final lowerMsg = msg.toLowerCase();

    // Phone number not found / Employee not found
    if (lowerMsg.contains('дугаар олдсонгүй') ||
        lowerMsg.contains('dugaar oldsongui') ||
        lowerMsg.contains('phone not found') ||
        lowerMsg.contains('user not found') ||
        lowerMsg.contains('employee not found') ||
        lowerMsg.contains('no employee found') ||
        lowerMsg.contains('бүртгэлгүй') ||
        lowerMsg.contains('бүртгэлтэй биш') ||
        lowerMsg.contains('бүртгэл байхгүй') ||
        msg.contains('❌ No employee found')) {
      return 'Утасны дугаар олдсонгүй';
    }

    // Wrong OTP
    if (lowerMsg.contains('буруу otp') ||
        lowerMsg.contains('wrong otp') ||
        lowerMsg.contains('invalid otp') ||
        lowerMsg.contains('otp код буруу') ||
        lowerMsg.contains('буруу otp код') ||
        msg.contains('Буруу OTP код') ||
        msg.contains('Буруу OTP')) {
      return 'OTP код буруу байна';
    }

    // OTP expired
    if (lowerMsg.contains('хүчингүй') ||
        lowerMsg.contains('expired') ||
        lowerMsg.contains('хугацаа дууссан')) {
      return 'OTP кодын хугацаа дууссан байна';
    }

    // OTP already used
    if (lowerMsg.contains('already used') ||
        lowerMsg.contains('аль хэдийн ашигласан')) {
      return 'OTP код аль хэдийн ашигласан байна';
    }

    // Too many attempts
    if (lowerMsg.contains('too many') ||
        lowerMsg.contains('хэт олон') ||
        lowerMsg.contains('оролдлого')) {
      return 'Хэт олон оролдлого хийгдлээ. Дахин оролдоно уу';
    }

    // Invalid reset token
    if (lowerMsg.contains('invalid token') ||
        lowerMsg.contains('хүчингүй токен')) {
      return 'Баталгаажуулалтын токен хүчингүй байна';
    }

    // Return original message if no translation found
    return msg;
  }

  Future<void> _resetPassword() async {
    if (_resetToken == null) {
      AppToast.show(
        context,
        'Баталгаажуулалт хийгээгүй байна',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final newPassword = _newPassCtrl.text;
    if (newPassword.isEmpty || newPassword.length != 4) {
      AppToast.show(
        context,
        'Нууц код 4 оронтой байх ёстой',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (newPassword != _confirmPassCtrl.text) {
      AppToast.show(
        context,
        'Нууц код таарахгүй байна',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() => _loading = true);
    final res = await ForgotPasswordService.resetPassword(
      _resetToken!,
      newPassword,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      setState(() => _step = 3);
      AppToast.show(
        context,
        res.data['message'] ?? 'Нууц код амжилттай солигдлоо',
        color: context.colors.success,
        icon: Icons.check_circle_outline_rounded,
      );
    } else {
      AppToast.show(
        context,
        res.message ?? 'Алдаа гарлаа',
        color: context.colors.destructive,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Step indicator
            if (_step < 3) ...[
              Row(
                children: List.generate(3, (i) {
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
                }),
              ),
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
      case 0:
        return _stepPhone(c);
      case 1:
        return _stepCode(c);
      case 2:
        return _stepNewPassword(c);
      case 3:
        return _stepSuccess(c);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Enter Phone Number ──
  Widget _stepPhone(AppColorScheme c) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.brandGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.phone_outlined, color: c.brandGreen, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          'Нууц код сэргээх',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: c.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Бүртгэлтэй утасны дугаараа оруулна уу (8 орон). '
          'Бид таньд OTP код илгээх болно.',
          style: TextStyle(fontSize: 14, color: c.mutedForeground, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _phoneCtrl,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            // Auto-continue when 8 digits are entered
            if (value.length == 8 && !_loading) {
              // Small delay to ensure the last digit is registered
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _phoneCtrl.text.length == 8) {
                  _sendCode();
                }
              });
            }
          },
          style: TextStyle(color: c.primary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Утасны дугаар (8 орон)',
            counterText: '',
            hintStyle: TextStyle(color: c.mutedForeground.withOpacity(0.6)),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: c.mutedForeground,
              size: 20,
            ),
            filled: true,
            fillColor: c.muted,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.brandGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Код илгээх',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.sms_outlined, color: c.info, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Код баталгаажуулах',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: c.mutedForeground,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Бид '),
              TextSpan(
                text: _phoneCtrl.text,
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w500),
              ),
              const TextSpan(
                text: ' утасны дугаар руу 6 оронтой OTP код илгээлээ.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 6-digit code fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              height: 54,
              child: TextField(
                controller: _codeControllers[i],
                focusNode: _codeFocuses[i],
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: i == 0
                    ? null
                    : 1, // Allow multiple digits in first field for autofill
                // Enable OTP autofill on the first field
                autofillHints: i == 0
                    ? const [AutofillHints.oneTimeCode]
                    : null,
                inputFormatters: i == 0
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: c.muted,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.brandGreen, width: 2),
                  ),
                ),
                onChanged: (v) {
                  // Handle paste/autofill: if first field receives multiple digits
                  if (i == 0 && v.length > 1) {
                    _handleOTPPaste(v);
                    // After paste, check if all 6 digits are filled
                    Future.delayed(const Duration(milliseconds: 150), () {
                      if (mounted && !_loading) {
                        final allFilled = _codeControllers.every(
                          (ctrl) => ctrl.text.isNotEmpty,
                        );
                        if (allFilled &&
                            _codeControllers.map((c) => c.text).join().length ==
                                6) {
                          _verifyCode();
                        }
                      }
                    });
                    return;
                  }

                  if (v.isNotEmpty && i < 5) {
                    _codeFocuses[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    _codeFocuses[i - 1].requestFocus();
                  }

                  // Auto-verify when last field (6th) is filled
                  if (i == 5 && v.isNotEmpty && !_loading) {
                    // Check if all 6 fields are filled
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted && !_loading) {
                        final allFilled = _codeControllers.every(
                          (ctrl) => ctrl.text.isNotEmpty,
                        );
                        if (allFilled &&
                            _codeControllers.map((c) => c.text).join().length ==
                                6) {
                          _verifyCode();
                        }
                      }
                    });
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Код ирээгүй юу? ',
              style: TextStyle(fontSize: 13, color: c.mutedForeground),
            ),
            GestureDetector(
              onTap: _loading
                  ? null
                  : () async {
                      // Resend OTP
                      final phone = _phoneCtrl.text.trim().replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      if (phone.isEmpty || phone.length != 8) {
                        AppToast.show(
                          context,
                          'Утасны дугаар 8 оронтой байх ёстой',
                          color: context.colors.destructive,
                          icon: Icons.error_outline_rounded,
                        );
                        return;
                      }

                      for (final ctrl in _codeControllers) {
                        ctrl.clear();
                      }
                      _codeFocuses[0].requestFocus();

                      setState(() => _loading = true);
                      final res = await ForgotPasswordService.requestOTP(phone);

                      if (!mounted) return;
                      setState(() => _loading = false);

                      if (res.success) {
                        // In development, OTP might be returned
                        if (res.data is Map && res.data['otp'] != null) {
                          _devOtp = res.data['otp'].toString();
                          if (_devOtp != null && _devOtp!.length == 6) {
                            for (int i = 0; i < 6; i++) {
                              _codeControllers[i].text = _devOtp![i];
                            }
                          }
                        }

                        AppToast.show(
                          context,
                          'OTP код дахин илгээгдлээ',
                          color: context.colors.success,
                          icon: Icons.check_circle_outline_rounded,
                        );
                      } else {
                        String errorMsg = _translateErrorMessage(
                          res.message ?? 'Алдаа гарлаа',
                        );
                        AppToast.show(
                          context,
                          errorMsg,
                          color: context.colors.destructive,
                          icon: Icons.error_outline_rounded,
                        );
                      }
                    },
              child: Text(
                'Дахин илгээх',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.brandGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Баталгаажуулах',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step 2: New PIN Code ──
  Widget _stepNewPassword(AppColorScheme c) {
    final passwordsMatch =
        _newPassCtrl.text.isNotEmpty &&
        _newPassCtrl.text == _confirmPassCtrl.text;

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.brandGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.lock_reset_rounded, color: c.brandGreen, size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          'Шинэ нууц код',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: c.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '4 оронтой шинэ нууц кодыг оруулна уу.',
          style: TextStyle(fontSize: 14, color: c.mutedForeground, height: 1.4),
        ),
        const SizedBox(height: 20),
        // New PIN code
        TextField(
          controller: _newPassCtrl,
          focusNode: _newPassFocus,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          obscureText: _obscureNew,
          onChanged: (value) {
            setState(() {});
            // Auto-advance to confirm field when 4 digits are entered
            if (value.length == 4 && !_loading) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted && _newPassCtrl.text.length == 4) {
                  _confirmPassFocus.requestFocus();
                }
              });
            }
          },
          style: TextStyle(color: c.primary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Шинэ нууц код',
            counterText: '',
            hintStyle: TextStyle(color: c.mutedForeground.withOpacity(0.6)),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: c.mutedForeground,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: c.mutedForeground,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            filled: true,
            fillColor: c.muted,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.brandGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Confirm PIN code
        TextField(
          controller: _confirmPassCtrl,
          focusNode: _confirmPassFocus,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          obscureText: _obscureConfirm,
          onChanged: (value) {
            setState(() {});
            // Auto-submit when 4 digits are entered and passwords match
            if (value.length == 4 && !_loading) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted &&
                    _confirmPassCtrl.text.length == 4 &&
                    _newPassCtrl.text.length == 4 &&
                    _newPassCtrl.text == _confirmPassCtrl.text) {
                  // Close keyboard and submit
                  FocusScope.of(context).unfocus();
                  _resetPassword();
                }
              });
            }
          },
          style: TextStyle(color: c.primary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Нууц код давтах',
            counterText: '',
            hintStyle: TextStyle(color: c.mutedForeground.withOpacity(0.6)),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: c.mutedForeground,
              size: 20,
            ),
            suffixIcon: _confirmPassCtrl.text.isNotEmpty
                ? Icon(
                    passwordsMatch
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: passwordsMatch ? c.success : c.destructive,
                    size: 22,
                  )
                : null,
            filled: true,
            fillColor: c.muted,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _confirmPassCtrl.text.isNotEmpty && !passwordsMatch
                    ? c.destructive
                    : c.inputBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.brandGreen, width: 2),
            ),
          ),
        ),
        if (_confirmPassCtrl.text.isNotEmpty && !passwordsMatch) ...[
          const SizedBox(height: 6),
          Text(
            'Нууц код таарахгүй байна',
            style: TextStyle(fontSize: 12, color: c.destructive),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed:
                _loading || !passwordsMatch || _newPassCtrl.text.length != 4
                ? null
                : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: c.muted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text(
                    'Нууц код шинэчлэх',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
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
          child: Icon(Icons.check_circle_rounded, color: c.success, size: 56),
        ),
        const SizedBox(height: 20),
        Text(
          'Амжилттай!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: c.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Таны нууц код амжилттай шинэчлэгдлээ.\n'
          'Шинэ нууц кодыгоороо нэвтэрнэ үү.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.mutedForeground, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.brandGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Нэвтрэх хуудас руу буцах',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// 4 оронтой нууц кодын хайрцагнууд. Доор нь ил биш TextField байрлаж
/// гар, autofill, хуулж буулгах зэргийг хариуцна; хайрцагнууд зөвхөн харагдац.
class _PinKhairtsag extends StatelessWidget {
  const _PinKhairtsag({
    required this.controller,
    required this.focusNode,
    required this.obscure,
    required this.idevkhteiUngu,
    required this.onSubmitted,
    required this.onChanged,
    this.aldaa,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final Color idevkhteiUngu;
  final String? aldaa;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(children: [
      ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) {
          final text = controller.text;
          final focused = focusNode.hasFocus;
          return Stack(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                _PinNud(
                  tsifr: i < text.length ? text[i] : null,
                  obscure: obscure,
                  idevkhtei: focused && (i == text.length || (i == 3 && text.length == 4)),
                  aldaatai: aldaa != null,
                  ungu: idevkhteiUngu,
                ),
              ],
            ]),
            // Ил биш оролт: хайрцагнуудын дээр байрлаж товшилтыг хүлээн авна
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  inputFormatters: [PinCodeFormatter()],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  maxLength: 4,
                  decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                  onSubmitted: (_) => onSubmitted(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ]);
        },
      ),
      if (aldaa != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(aldaa!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.destructive)),
        ),
    ]);
  }
}

class _PinNud extends StatelessWidget {
  const _PinNud({
    required this.tsifr,
    required this.obscure,
    required this.idevkhtei,
    required this.aldaatai,
    required this.ungu,
  });

  final String? tsifr;
  final bool obscure, idevkhtei, aldaatai;
  final Color ungu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final duurgsen = tsifr != null;
    final khuree = aldaatai
        ? c.destructive
        : idevkhtei
            ? ungu
            : duurgsen
                ? ungu.withValues(alpha: 0.35)
                : Colors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 58,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: duurgsen ? ungu.withValues(alpha: 0.07) : c.muted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: khuree, width: idevkhtei ? 1.8 : 1.2),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 160),
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: !duurgsen
            ? (idevkhtei
                ? Container(key: const ValueKey('k'), width: 2, height: 22, color: ungu)
                : Container(
                    key: const ValueKey('h'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.mutedForeground.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ))
            : obscure
                ? Container(
                    key: const ValueKey('o'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                  )
                : Text(
                    tsifr!,
                    key: ValueKey('t$tsifr'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: c.primary),
                  ),
      ),
    );
  }
}
