import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      duration: const Duration(seconds: 30),
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
            AppToast.show(
              context,
              'Сэсси хугацаа дууссан байна. Нууц кодоор нэвтэрнэ үү.',
            );
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
      backgroundColor: const Color(0xFF05070D),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, box) {
          final urgun =
              box.maxWidth >= 720 || box.maxWidth > box.maxHeight * 1.3;
          if (urgun) {
            // iPad, Galaxy Fold (дэлгэж), хэвтээ утас: hero зүүн, форм баруун
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _Hero(
                    loop: _loopCtrl,
                    intro: _animCtrl,
                    onSongokh: _modulSongokh,
                    urgun: true,
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
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(36),
                        ),
                      ),
                      child: SafeArea(
                        left: false,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 28,
                            ),
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
              ],
            );
          }

          // Утас босоо: hero дээр, цагаан sheet доороос гулсаж гарна
          final deed = MediaQuery.paddingOf(context).top;
          final dood = MediaQuery.paddingOf(context).bottom;
          // Формд хэрэгтэй өндрийг (хувилбарын мөр хүртэл) эхэлж өгөөд үлдсэнийг hero авна
          final formKheregtei = 600.0 + dood;
          final heroH = (box.maxHeight - formKheregtei + 32).clamp(
            210.0,
            380.0,
          );
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroH,
                // Hero статус мөрийн доор хүртэл үргэлжилнэ
                child: _Hero(
                  loop: _loopCtrl,
                  intro: _animCtrl,
                  onSongokh: _modulSongokh,
                  compact: false,
                  deedZai: deed,
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.only(top: heroH - 32),
                child: _SheetSlide(
                  intro: _animCtrl,
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: box.maxHeight - heroH + 32,
                    ),
                    decoration: BoxDecoration(
                      color: c.cardBackground,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
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
            ],
          );
        },
      ),
    );
  }

  /// Витрины модулийг гараар сонгох (давталт тэр модулиас үргэлжилнэ)
  void _modulSongokh(int i) {
    _loopCtrl.value = i / _heroModuluud.length;
    if (!_khudulguunKhasakh) _loopCtrl.repeat();
  }

  Widget _buildForm(AppColorScheme c) {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    Widget shoshgo(String t) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(t, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
    );
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Лого + систем
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_logo_round.png',
                    width: 42,
                    height: 42,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FSM',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: c.primary,
                        ),
                      ),
                      Text(
                        'Байгууллагын удирдлагын нэгдсэн систем',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: c.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            shoshgo('Нэвтрэх нэр'),
            TextFormField(
              controller: _emailCtrl,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              style: TextStyle(color: c.primary, fontSize: 16),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              onFieldSubmitted: (_) => _pinFocus.requestFocus(),
              decoration: _pillDeco(
                c,
                'Нэвтрэх нэрээ оруулна уу',
                Icons.person_outline_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Нэвтрэх нэрээ оруулна уу'
                  : null,
            ),
            const SizedBox(height: 18),
            shoshgo('Нууц код'),
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
                  if (v.length == 4 && _emailCtrl.text.trim().isNotEmpty)
                    _handleLogin();
                },
              ),
            ),
            const SizedBox(height: 8),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            activeColor: _heroUngu,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: BorderSide(
                              color: c.mutedForeground.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Намайг сана',
                          style: TextStyle(
                            fontSize: 14,
                            color: c.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showForgotPassword(context),
                  style: TextButton.styleFrom(
                    foregroundColor: _heroUngu,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Нууц код мартсан?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _GyalbaaTovch(
                    loop: _loopCtrl,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                ),
                // Face ID / хурууны хээ — нэвтрэх товчны хажууд
                if (_bioSupported) ...[
                  const SizedBox(width: 12),
                  Tooltip(
                    message: ios
                        ? 'Face ID-аар нэвтрэх'
                        : 'Хурууны хээгээр нэвтрэх',
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleBiometricLogin,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: _heroUngu,
                          side: BorderSide(
                            color: _heroUngu.withValues(alpha: 0.5),
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Icon(
                          ios ? Icons.face_unlock_rounded : Icons.fingerprint,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            // Модулиуд — нэг бүртгэлээр
            AnimatedBuilder(
              animation: _loopCtrl,
              builder: (context, _) {
                final n = _heroModuluud.length;
                final idx = (_loopCtrl.value * n).floor() % n;
                return Row(
                  children: [
                    SizedBox(
                      height: 36,
                      width: 36 + (n - 1) * 26.0,
                      child: Stack(
                        children: [
                          for (var i = 0; i < n; i++)
                            Positioned(
                              left: i * 26.0,
                              child: GestureDetector(
                                onTap: () => _modulSongokh(i),
                                child: AnimatedScale(
                                  scale: i == idx ? 1.12 : 1,
                                  duration: const Duration(milliseconds: 250),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _heroModuluud[i].gerel,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: c.cardBackground,
                                        width: 3,
                                      ),
                                    ),
                                    child: Icon(
                                      _heroModuluud[i].icon,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$n модуль нэг дор',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              _appVersion.isEmpty
                  ? '© ${DateTime.now().year} Zevtabs LLC'
                  : '© ${DateTime.now().year} Zevtabs LLC, v$_appVersion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: c.mutedForeground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _pillDeco(AppColorScheme c, String hint, IconData icon) {
    OutlineInputBorder border(Color color, [double w = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: c.mutedForeground.withValues(alpha: 0.8),
        fontSize: 15,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 10),
        child: Icon(icon, color: c.mutedForeground, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0),
      filled: true,
      fillColor: c.muted,
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
      border: border(Colors.transparent),
      enabledBorder: border(c.border),
      focusedBorder: border(_heroUngu, 2),
      errorBorder: border(c.destructive),
      focusedErrorBorder: border(c.destructive, 2),
      errorStyle: const TextStyle(height: 1.2),
    );
  }
}

const _heroUngu = Color(0xFFF18F02);

/// Нээгдэхэд доороос (эсвэл баруунаас) гулсаж гарах
class _SheetSlide extends StatelessWidget {
  const _SheetSlide({
    required this.intro,
    required this.child,
    this.fromRight = false,
  });
  final Animation<double> intro;
  final Widget child;
  final bool fromRight;
  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(
      parent: intro,
      curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      builder: (context, ch) => FractionalTranslation(
        translation: fromRight
            ? Offset(0.25 * (1 - a.value), 0)
            : Offset(0, 0.35 * (1 - a.value)),
        child: Opacity(opacity: a.value.clamp(0, 1), child: ch),
      ),
      child: child,
    );
  }
}

/// Hero-д ээлжлэн харагдах модуль (вэбийн нэвтрэх хуудасны витринтэй ижил).
/// Шинэ модуль нэмэхдээ [_heroModuluud]-д нэг мөр нэмнэ.
class _HeroModul {
  const _HeroModul({
    required this.ner,
    required this.tomUg,
    required this.bichmel,
    required this.chipNer,
    required this.chipUtga,
    required this.chipKhuvi,
    required this.bogino,
    required this.tailbar,
    required this.icon,
    required this.nemelt,
    required this.tod,
    required this.gerel,
    required this.gun,
  });
  final String ner;

  /// Картын өргөнийг дүүргэх том 3D үг
  final String tomUg;

  /// Гарчгийг хөндлөн гатлах гар бичмэл үг
  final String bichmel;

  /// Тоон үзүүлэлт (0-ээс өснө; цаг бол хөдлөхгүй)
  final String chipNer;
  final String chipUtga;
  final double chipKhuvi;
  final String bogino;
  final String tailbar;
  final IconData icon;

  /// Гарчигт хамаарах нэмэлт icon-ууд (хөвөх, арын хээ)
  final List<IconData> nemelt;
  final Color tod;
  final Color gerel;
  final Color gun;
}

const _heroModuluud = <_HeroModul>[
  _HeroModul(
    ner: 'Төлөвлөгөө & Гүйцэтгэл',
    tomUg: 'ЗОРИЛТ',
    bichmel: 'гүйцэтгэл',
    chipNer: 'Q4 гүйцэтгэл',
    chipUtga: '82%',
    chipKhuvi: 0.82,
    bogino: 'Төлөвлөгөө',
    tailbar: 'Зорилт, төлөвлөгөөгөө тавьж, гүйцэтгэлийг бодит цагаар хэмжинэ.',
    icon: Icons.track_changes_rounded,
    nemelt: [
      Icons.bar_chart_rounded,
      Icons.check_rounded,
      Icons.star_outline_rounded,
    ],
    tod: Color(0xFF8B7BFF),
    gerel: Color(0xFF6D5DFC),
    gun: Color(0xFF1B1450),
  ),
  _HeroModul(
    ner: 'Хүний нөөцийн менежмент',
    tomUg: 'БАГ',
    bichmel: 'нөөц',
    chipNer: 'Идэвхтэй ажилтан',
    chipUtga: '248',
    chipKhuvi: 0.68,
    bogino: 'Хүний нөөц',
    tailbar: 'Ажилтны бүртгэл, албан тушаал, гэрээ, үнэлгээг нэг дор удирдана.',
    icon: Icons.groups_outlined,
    nemelt: [
      Icons.badge_outlined,
      Icons.star_outline_rounded,
      Icons.check_rounded,
    ],
    tod: Color(0xFF2DD4BF),
    gerel: Color(0xFF0FA3A3),
    gun: Color(0xFF062B33),
  ),
  _HeroModul(
    ner: 'Цагийн бүртгэл',
    tomUg: 'ИРЦ',
    bichmel: 'цаг',
    chipNer: 'Цагтаа ирлээ',
    chipUtga: '08:52',
    chipKhuvi: 0.94,
    bogino: 'Цаг бүртгэл',
    tailbar: 'Ирц, хоцролт, чөлөө, ээлжийн амралтыг нэг товчоор бүртгэнэ.',
    icon: Icons.schedule_rounded,
    nemelt: [
      Icons.event_available_outlined,
      Icons.check_rounded,
      Icons.notifications_none_rounded,
    ],
    tod: Color(0xFF60A5FA),
    gerel: Color(0xFF2563EB),
    gun: Color(0xFF0B1A46),
  ),
  _HeroModul(
    ner: 'Цалингийн тооцоолол',
    tomUg: 'ЦАЛИН',
    bichmel: 'тооцоо',
    chipNer: 'Сарын цалин',
    chipUtga: '1,850,000',
    chipKhuvi: 1.0,
    bogino: 'Цалин',
    tailbar: 'Ирц, илүү цагаас цалинг автоматаар тооцож, цаг алдалгүй олгоно.',
    icon: Icons.account_balance_wallet_outlined,
    nemelt: [
      Icons.monetization_on_outlined,
      Icons.bar_chart_rounded,
      Icons.check_rounded,
    ],
    tod: Color(0xFFFBBF24),
    gerel: Color(0xFFD97706),
    gun: Color(0xFF3A1D05),
  ),
  _HeroModul(
    ner: 'Харуулын хяналтын систем',
    tomUg: 'ХАРУУЛ',
    bichmel: 'хяналт',
    chipNer: 'Эргүүлийн цэг',
    chipUtga: '12 / 12',
    chipKhuvi: 1.0,
    bogino: 'Харуул',
    tailbar: 'Харуул, эргүүлийн цэгүүдийг хянаж, зөрчлийг шууд мэдэгдэнэ.',
    icon: Icons.verified_user_outlined,
    nemelt: [
      Icons.location_on_outlined,
      Icons.notifications_none_rounded,
      Icons.check_rounded,
    ],
    tod: Color(0xFFFB7185),
    gerel: Color(0xFFE11D48),
    gun: Color(0xFF3B0A18),
  ),
];

/// Нэг давталт (бүх модуль) хэдэн секунд — модуль бүр 6 сек
const _heroDavtaltSek = 30.0;
const _modulSek = 6.0;

/// Вэбийн FsmHero: модулийн өнгөт гэрэл, тор, арын icon хээ, том icon
/// цагиргууд дунд, хөвөх холбогдох icon-ууд, үсэг үсгээр гарах гарчиг.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.loop,
    required this.intro,
    required this.compact,
    required this.onSongokh,
    this.urgun = false,
    this.deedZai = 0,
    this.zuunZai = 0,
  });
  final Animation<double> loop;
  final Animation<double> intro;
  final bool compact;
  final bool urgun;
  final ValueChanged<int> onSongokh;
  final double deedZai;
  final double zuunZai;

  @override
  Widget build(BuildContext context) {
    final n = _heroModuluud.length;
    final khudulgukhgui = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([loop, intro]),
      builder: (context, _) {
        final bairlal = loop.value * n;
        final idx = bairlal.floor() % n;
        final modul = _heroModuluud[idx];
        final sek = loop.value * _heroDavtaltSek;
        // Тухайн модуль эхэлснээс хойш өнгөрсөн хугацаа (үсгийн анимацид)
        final ongorson = khudulgukhgui
            ? 99.0
            : (bairlal - bairlal.floor()) * _modulSek;
        final introA = CurvedAnimation(
          parent: intro,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
        ).value;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: idx.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          builder: (context, v, _) {
            final i0 = v.floor().clamp(0, n - 1);
            final i1 = v.ceil().clamp(0, n - 1);
            final f = v - v.floor();
            Color hol(Color Function(_HeroModul) k) =>
                Color.lerp(k(_heroModuluud[i0]), k(_heroModuluud[i1]), f)!;
            return ClipRect(
              child: CustomPaint(
                painter: _VitrinPainter(
                  gerel: hol((m) => m.gerel),
                  gun: hol((m) => m.gun),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: deedZai, left: zuunZai),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final h = box.maxHeight;
                      final w = box.maxWidth;
                      final jijig = compact || h < 260;
                      final garchigFont = jijig
                          ? 23.0
                          : (w < 360 ? 25.0 : 29.0);
                      final zai = w < 360 ? 20.0 : 24.0;
                      final dood = compact ? 18.0 : (urgun ? 24.0 : 46.0);
                      final dursH = (math.min(
                        w * (urgun ? 0.34 : 0.4),
                        h * 0.36,
                      )).clamp(96.0, 240.0);
                      return Opacity(
                        opacity: introA,
                        child: Stack(
                          children: [
                            // Арын хээ: модулийн icon-ууд бүдгээр тархаж хөвнө
                            ..._ikonKhee(modul, w, h, sek),
                            // Том 3D үг: картын өргөнийг дүүргэнэ
                            Positioned(
                              left: zai * 0.6,
                              right: zai * 0.6,
                              top: h * (jijig ? 0.16 : 0.18),
                              height: h * (jijig ? 0.42 : 0.38),
                              child: _TomUg3D(
                                key: ValueKey('u-${modul.tomUg}'),
                                ug: modul.tomUg,
                                ongorson: ongorson,
                                sek: sek,
                                tod: modul.tod,
                                gun: modul.gun,
                              ),
                            ),
                            // "Субъект": үгийн доод хэсгийг дарж урд нь хөвнө (гүний эффект)
                            Positioned(
                              left: (w - dursH) / 2,
                              top: h * (jijig ? 0.40 : 0.42),
                              width: dursH,
                              height: dursH,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 600),
                                transitionBuilder: (ch, a) => FadeTransition(
                                  opacity: a,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, 0.18),
                                      end: Offset.zero,
                                    ).animate(a),
                                    child: ch,
                                  ),
                                ),
                                child: _ModulDurs(
                                  key: ValueKey(modul.ner),
                                  modul: modul,
                                  sek: sek,
                                ),
                              ),
                            ),
                            // Дээд мөр: хөдөлгөөнт icon
                            Positioned(
                              left: zai,
                              right: zai,
                              top: jijig ? 10 : 16,
                              child: Row(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 450),
                                    transitionBuilder: (ch, a) =>
                                        ScaleTransition(
                                          scale: a,
                                          child: FadeTransition(
                                            opacity: a,
                                            child: ch,
                                          ),
                                        ),
                                    child: _KhudulgurIcon(
                                      key: ValueKey(modul.ner),
                                      modul: modul,
                                      sek: sek,
                                      khemjee: jijig ? 40 : 46,
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                            // Доод мөр: [03 / 05] НЭР + тайлбар, өргөн дэлгэцэнд pill-үүд
                            Positioned(
                              left: zai,
                              right: zai,
                              bottom: dood,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '[${(idx + 1).toString().padLeft(2, '0')} / ${n.toString().padLeft(2, '0')}]  ',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text: modul.ner.toUpperCase(),
                                          style: TextStyle(color: modul.tod),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: jijig ? 12.5 : 14,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  if (!jijig) ...[
                                    const SizedBox(height: 6),
                                    _UgTailbar(
                                      text: modul.tailbar,
                                      ongorson: ongorson - 0.3,
                                    ),
                                  ],
                                  if (urgun) ...[
                                    const SizedBox(height: 14),
                                    _ModulPilluud(
                                      idx: idx,
                                      onSongokh: onSongokh,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Уулын оронд: гарчигт хамаарах том бүдэг outline icon-ууд
  List<Widget> _ikonKhee(_HeroModul m, double w, double h, double sek) {
    const bairlal = [
      (0.02, 0.50, 0.24, -12.0),
      (0.30, 0.66, 0.16, 10.0),
      (0.52, 0.46, 0.28, -6.0),
      (0.78, 0.68, 0.18, 14.0),
      (0.88, 0.30, 0.13, -18.0),
      (0.14, 0.24, 0.11, 8.0),
    ];
    final iconuud = [m.icon, ...m.nemelt];
    return [
      for (var i = 0; i < bairlal.length; i++)
        Builder(
          builder: (_) {
            final b = bairlal[i];
            final khemjee = w * b.$3;
            final faza = sek * 2 * math.pi / (9 + i * 1.3) + i;
            return Positioned(
              left: w * b.$1 - 10 * math.sin(faza),
              top: h * b.$2 - 12 * math.sin(faza),
              child: Transform.rotate(
                angle: (b.$4 + 6 * math.sin(faza)) * math.pi / 180,
                child: Icon(
                  iconuud[i % iconuud.length],
                  size: khemjee,
                  color: m.tod.withValues(alpha: 0.13),
                ),
              ),
            );
          },
        ),
    ];
  }
}

/// Үсэг бүр доороос эргэж, бүдгээс тод болж гарна
class _UsegGarchig extends StatelessWidget {
  const _UsegGarchig({
    required this.ner,
    required this.ongorson,
    required this.font,
  });
  final String ner;
  final double ongorson;
  final double font;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, b) {
        // Хамгийн урт үг мөрөнд багтахуйц хэмжээ
        var f = font;
        TextStyle st(double x) => TextStyle(
          color: Colors.white,
          fontSize: x,
          height: 1.12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        );
        if (b.maxWidth.isFinite) {
          for (final ug in ner.split(' ')) {
            final tp = TextPainter(
              text: TextSpan(text: '$ug ', style: st(f)),
              textDirection: TextDirection.ltr,
            )..layout();
            if (tp.width > b.maxWidth) f = f * b.maxWidth / tp.width;
          }
        }
        final style = st(f);
        var n = 0;
        return Semantics(
          label: ner,
          child: ExcludeSemantics(
            child: Wrap(
              children: [
                for (final ug in ner.split(' '))
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: b.maxWidth.isFinite
                          ? b.maxWidth
                          : double.infinity,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final tem in ug.characters)
                            Builder(
                              builder: (_) {
                                final p = Curves.easeOutCubic.transform(
                                  ((ongorson - n++ * 0.028) / 0.6).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                );
                                return Opacity(
                                  opacity: p,
                                  child: Transform(
                                    alignment: Alignment.bottomCenter,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.002)
                                      ..translateByDouble(
                                        0.0,
                                        (1 - p) * font * 0.45,
                                        0.0,
                                        1.0,
                                      )
                                      ..rotateX(-(1 - p) * 1.3),
                                    child: Text(tem, style: style),
                                  ),
                                );
                              },
                            ),
                          Text(' ', style: style),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Картын өргөнийг дүүргэх том 3D үг: модулийн бараан өнгөөр 7 давхар
/// "шахалт", нүүр нь цагаанаас модулийн өнгө рүү уусна. Үсэг бүр доороос
/// гарч ирэх ба үг бүхэлдээ 3D-д аажим хазайна.
class _TomUg3D extends StatelessWidget {
  const _TomUg3D({
    super.key,
    required this.ug,
    required this.ongorson,
    required this.sek,
    required this.tod,
    required this.gun,
  });
  final String ug;
  final double ongorson;
  final double sek;
  final Color tod;
  final Color gun;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, b) {
        TextStyle st(double f, Color c, {List<Shadow>? shadows}) =>
            GoogleFonts.unbounded(
              fontSize: f,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -f * 0.03,
              color: c,
              shadows: shadows,
            );
        // 100px-ээр хэмжээд өргөн/өндөрт тааруулна
        final tp = TextPainter(
          text: TextSpan(text: ug, style: st(100, Colors.white)),
          textDirection: TextDirection.ltr,
        )..layout();
        final f = math.min(
          100 * b.maxWidth * 0.94 / tp.width,
          b.maxHeight * 0.9,
        );
        final gun3 = f * 0.012;
        final sway = math.sin(sek * 2 * math.pi / 7) * 0.16;
        final usgnuud = ug.characters.toList();
        return Center(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateY(sway)
              ..rotateX(-0.06),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < usgnuud.length; i++)
                  Builder(
                    builder: (_) {
                      final p = Curves.easeOutCubic.transform(
                        ((ongorson - i * 0.06) / 0.7).clamp(0.0, 1.0),
                      );
                      return Opacity(
                        opacity: p,
                        child: Transform.translate(
                          offset: Offset(0, (1 - p) * f * 0.6),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Шахалтын давхаргууд (гүн рүү)
                              for (var k = 7; k >= 1; k--)
                                Transform.translate(
                                  offset: Offset(k * gun3, k * gun3 * 1.5),
                                  child: Text(
                                    usgnuud[i],
                                    style: st(
                                      f,
                                      Color.lerp(gun, Colors.black, k / 14)!,
                                      shadows: k == 7
                                          ? [
                                              Shadow(
                                                color: gun.withValues(
                                                  alpha: 0.85,
                                                ),
                                                blurRadius: f * 0.25,
                                                offset: Offset(0, f * 0.16),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              // Нүүр: цагаанаас модулийн өнгө рүү
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (r) => LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Colors.white, tod],
                                  stops: const [0, 0.4, 1],
                                ).createShader(r),
                                child: Text(
                                  usgnuud[i],
                                  style: st(f, Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Тайлбар үг үгээр гарна
class _UgTailbar extends StatelessWidget {
  const _UgTailbar({required this.text, required this.ongorson});
  final String text;
  final double ongorson;

  @override
  Widget build(BuildContext context) {
    final ugs = text.split(' ');
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Wrap(
          children: [
            for (var i = 0; i < ugs.length; i++)
              Builder(
                builder: (_) {
                  final p = Curves.easeOutCubic.transform(
                    ((ongorson - i * 0.045) / 0.6).clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: p,
                    child: Transform.translate(
                      offset: Offset(0, (1 - p) * 10),
                      child: Text(
                        '${ugs[i]} ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Өргөн дэлгэцэнд: модуль сонгох icon pill-үүд (сонгосон нь нэрээ дэлгэнэ)
class _ModulPilluud extends StatelessWidget {
  const _ModulPilluud({required this.idx, required this.onSongokh});
  final int idx;
  final ValueChanged<int> onSongokh;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _heroModuluud.length; i++)
              GestureDetector(
                onTap: () => onSongokh(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 36,
                  padding: EdgeInsets.symmetric(horizontal: i == idx ? 12 : 9),
                  decoration: BoxDecoration(
                    color: i == idx ? _heroModuluud[i].tod : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _heroModuluud[i].icon,
                        size: 18,
                        color: i == idx
                            ? const Color(0xFF0B1020)
                            : Colors.white70,
                      ),
                      if (i == idx) ...[
                        const SizedBox(width: 6),
                        Text(
                          _heroModuluud[i].bogino,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0B1020),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Том дүрслэл: гэрэл, эргэх тасархай цагиргууд, шилэн хавтан дахь том icon,
/// эргэн тойронд хөвөх холбогдох icon-ууд
class _ModulDurs extends StatelessWidget {
  const _ModulDurs({super.key, required this.modul, required this.sek});
  final _HeroModul modul;
  final double sek;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, b) {
        final s = b.maxWidth;
        final amisgal = 1 + 0.12 * math.sin(sek * 2 * math.pi / 5);
        final khovokh = math.sin(sek * 2 * math.pi / 4.5) * 5;
        const bairlal = [
          Offset(0.02, 0.14),
          Offset(0.84, 0.36),
          Offset(0.14, 0.82),
        ];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Transform.scale(
                scale: amisgal,
                child: Container(
                  width: s * 0.62,
                  height: s * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: modul.tod.withValues(alpha: 0.35),
                        blurRadius: s * 0.25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.rotate(
                angle: sek * 2 * math.pi / 40,
                child: CustomPaint(
                  painter: _TasarkhaiTsagirag(
                    color: modul.tod.withValues(alpha: 0.45),
                    radiusFactor: 0.44,
                    dash: 6,
                    gap: 9,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.rotate(
                angle: -sek * 2 * math.pi / 60,
                child: CustomPaint(
                  painter: _TasarkhaiTsagirag(
                    color: modul.tod.withValues(alpha: 0.22),
                    radiusFactor: 0.54,
                    dash: 2,
                    gap: 7,
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: s * 0.4,
                height: s * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      modul.tod.withValues(alpha: 0.85),
                      modul.gerel.withValues(alpha: 0.6),
                      modul.gun.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(s * 0.13),
                  boxShadow: [
                    BoxShadow(
                      color: modul.gun.withValues(alpha: 0.8),
                      blurRadius: s * 0.18,
                      offset: Offset(0, s * 0.08),
                    ),
                  ],
                ),
                child: Transform.translate(
                  offset: Offset(0, khovokh),
                  child: Transform.scale(
                    scale: 1 + 0.08 * math.sin(sek * 2 * math.pi / 3.2),
                    child: Transform.rotate(
                      angle: math.sin(sek * 2 * math.pi / 3.2) * 0.12,
                      child: Icon(
                        modul.icon,
                        size: s * 0.22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (var i = 0; i < modul.nemelt.length; i++)
              Positioned(
                left: s * bairlal[i].dx,
                top:
                    s * bairlal[i].dy +
                    math.sin(sek * 2 * math.pi / 3.2 + i * 1.2) * 5,
                child: Transform.rotate(
                  angle:
                      math.sin(sek * 2 * math.pi / (3.2 + i * 0.7) + i) * 0.18,
                  child: Container(
                    width: s * 0.15,
                    height: s * 0.15,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          modul.tod.withValues(alpha: 0.75),
                          modul.gerel.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(s * 0.05),
                      boxShadow: [
                        BoxShadow(
                          color: modul.gun.withValues(alpha: 0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      modul.nemelt[i],
                      size: s * 0.075,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TasarkhaiTsagirag extends CustomPainter {
  _TasarkhaiTsagirag({
    required this.color,
    required this.radiusFactor,
    required this.dash,
    required this.gap,
  });
  final Color color;
  final double radiusFactor, dash, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * radiusFactor;
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final toirog = 2 * math.pi * r;
    final alkham = (dash + gap) / toirog * 2 * math.pi;
    final urt = dash / toirog * 2 * math.pi;
    for (var a = 0.0; a < 2 * math.pi; a += alkham) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a,
        urt,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TasarkhaiTsagirag o) => o.color != color;
}

/// Хөвж, импульс цацруулж, үе үе сэгсрэх модулийн icon
class _KhudulgurIcon extends StatelessWidget {
  const _KhudulgurIcon({
    super.key,
    required this.modul,
    required this.sek,
    required this.khemjee,
  });
  final _HeroModul modul;
  final double sek;
  final double khemjee;

  @override
  Widget build(BuildContext context) {
    final khovokh = math.sin(sek * 2 * math.pi / 3.2) * 3;
    final impuls = (sek % 2.2) / 2.2;
    final sehgreh = (sek % 4) / 4;
    final ergelt = sehgreh > 0.78 && sehgreh < 0.94
        ? math.sin((sehgreh - 0.78) / 0.16 * 2 * math.pi) * 0.16
        : 0.0;
    final r = khemjee * 0.3;
    return SizedBox(
      width: khemjee + 16,
      height: khemjee + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1 + impuls * 0.35,
            child: Container(
              width: khemjee,
              height: khemjee,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                color: modul.tod.withValues(alpha: 0.35 * (1 - impuls)),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, khovokh),
            child: Container(
              width: khemjee,
              height: khemjee,
              decoration: BoxDecoration(
                color: modul.tod,
                borderRadius: BorderRadius.circular(r),
                boxShadow: [
                  BoxShadow(
                    color: modul.tod.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: ergelt,
                child: Icon(
                  modul.icon,
                  size: khemjee * 0.5,
                  color: const Color(0xFF0B1020),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Арын давхарга: модулийн өнгөт гэрэл, тор, доод бараан уусалт
class _VitrinPainter extends CustomPainter {
  _VitrinPainter({required this.gerel, required this.gun});
  final Color gerel, gun;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.44, -0.4),
          radius: 1.1,
          colors: [gerel.withValues(alpha: 0.95), gun, const Color(0xFF05070D)],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    final tor = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(Offset(0, h * i / 6), Offset(w, h * i / 6), tor);
    }
    for (var i = 1; i < 8; i++) {
      canvas.drawLine(Offset(w * i / 8, 0), Offset(w * i / 8, h), tor);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF04060B).withValues(alpha: 0.85),
          ],
          stops: const [0.45, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_VitrinPainter o) => o.gerel != gerel || o.gun != gun;
}

/// Нэвтрэх товч: theme градиент, сум, үе үе гялбаа гүйнэ
class _GyalbaaTovch extends StatelessWidget {
  const _GyalbaaTovch({
    required this.loop,
    required this.isLoading,
    required this.onPressed,
  });
  final Animation<double> loop;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE67E00), _heroUngu]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _heroUngu.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Stack(
            children: [
              // Гялбаа
              AnimatedBuilder(
                animation: loop,
                builder: (context, _) {
                  final f = ((loop.value * _heroDavtaltSek) % 3.8) / 3.8;
                  final p = (f / 0.55).clamp(0.0, 1.0);
                  return Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(-0.4 + p * 1.8, 0),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.28,
                        child: Transform(
                          transform: Matrix4.skewX(-0.35),
                          child: Container(
                            color: Colors.white.withValues(
                              alpha: p > 0 && p < 1 ? 0.18 : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('ach'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          key: ValueKey('txt'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Нэвтрэх',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return Column(
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([controller, focusNode]),
          builder: (context, _) {
            final text = controller.text;
            final focused = focusNode.hasFocus;
            return Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      _PinNud(
                        tsifr: i < text.length ? text[i] : null,
                        obscure: obscure,
                        idevkhtei:
                            focused &&
                            (i == text.length || (i == 3 && text.length == 4)),
                        aldaatai: aldaa != null,
                        ungu: idevkhteiUngu,
                      ),
                    ],
                  ],
                ),
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
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onSubmitted: (_) => onSubmitted(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (aldaa != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              aldaa!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.destructive),
            ),
          ),
      ],
    );
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
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: !duurgsen
            ? (idevkhtei
                  ? Container(
                      key: const ValueKey('k'),
                      width: 2,
                      height: 22,
                      color: ungu,
                    )
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
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
              )
            : Text(
                tsifr!,
                key: ValueKey('t$tsifr'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
      ),
    );
  }
}
