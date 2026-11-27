import 'ai_tuslakh_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/project_service.dart';
import '../services/fcm_service.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'irts_screen.dart';
import 'nuur_screen.dart';
import 'tsalin_screen.dart';
import 'udirdlaga_screen.dart';
import 'zuvshuurul_screen.dart';
import 'login_screen.dart';
import 'performance_screen.dart';
import '../widgets/ai_tovch.dart';
import '../widgets/gradient_tolgoi.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isLoggedIn = false;
  bool _isCheckingSession = true;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _inactivityTimer?.cancel();
    if (_isLoggedIn) {
      _inactivityTimer = Timer(const Duration(minutes: 10), () {
        debugPrint('[AutoLogout] 15 mins of inactivity. Logging out...');
        _handleLogout();
      });
    }
  }

  void _handleInteraction([_]) {
    if (_isLoggedIn) _startTimer();
  }

  Future<void> _checkSession() async {
    final restored = await AuthService.restoreSession();
    if (mounted) {
      setState(() {
        _isLoggedIn = restored;
        _isCheckingSession = false;
      });
      if (restored) {
        // fsmBack irts токеныг ч хүлээн авдаг тул бүх хэрэглэгч FSM socket-той
        SocketService.connect();
        _startTimer();
      }
    }
  }

  void _handleLoggedIn() {
    setState(() => _isLoggedIn = true);
    // fsmBack irts токеныг ч хүлээн авдаг тул бүх хэрэглэгч FSM socket-той
    SocketService.connect();
    _startTimer();
  }

  void _handleLogout() async {
    _inactivityTimer?.cancel();
    SocketService.disconnect();
    // Deactivate FCM token before logout (FSM болон irts хэрэглэгч хоёулаа бүртгүүлдэг)
    await FCMService.deactivateToken();
    await AuthService.logout();
    if (mounted) setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      final c = context.colors;
      return Scaffold(
        backgroundColor: c.background,
        body: Center(child: CircularProgressIndicator(color: c.brandGreen)),
      );
    }
    if (!_isLoggedIn) return LoginScreen(onLoggedIn: _handleLoggedIn);
    return Listener(
      onPointerDown: _handleInteraction,
      behavior: HitTestBehavior.translucent,
      child: _HomeShell(onLogout: _handleLogout),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.onLogout});
  final VoidCallback onLogout;
  @override
  State<_HomeShell> createState() => _HomeShellState();
}

/// Аппын модуль. [systemuud]: аль системийн хэрэглэгчид харагдах, тус бүрийн
/// шаардах цонхны эрх (zevtabs/turees эсвэл irts-ийн tsonkhniiErkhuud).
/// Эрхийн жагсаалт null бол тухайн системийн бүх ажилтанд харагдана;
/// байвал аль нэг зам нь ажилтны tsonkhniiErkhuud-д байх ёстой.
class FsmModul {
  const FsmModul(
    this.icon,
    this.ner,
    this.khuudas, {
    this.systemuud = const {'fsm': null},
    this.zuvkhunAdmin = false,
    this.zevtabsShaardlagatai = false,
    this.tolgoiKheregtei = false,
    this.tusdaaKhuudas,
  });
  final IconData icon;
  final String ner;
  final Widget khuudas;

  /// "Цэс"-ээс тусдаа хуудсаар нээхэд өөрийн AppBar-гүй бол гарчиг/буцах нэмнэ
  final bool tolgoiKheregtei;

  /// "Цэс"-ээс нээхэд [khuudas]-ын оронд харуулах хувилбар (жишээ нь буцах товчтой)
  final Widget? tusdaaKhuudas;
  final Map<String, List<String>?> systemuud;

  /// FSM-д зөвхөн Admin; irts-д Admin эсвэл заасан удирдлагын цонхтой хүн
  final bool zuvkhunAdmin;

  /// true бол zevtabs-ийн байгууллагын цонхны мэдээлэл заавал байх ёстой
  /// (мэдэгдэхгүй үед харуулахгүй) — Цалин зэрэг лицензтэй модуль.
  final bool zevtabsShaardlagatai;

  /// FSM+irts хэрэглэгч: аль нэг бүртгэл нь эрхтэй бол харагдана (табууд нийлнэ).
  /// irts түлхүүртэй модуль (Ирц, Удирдлага...) холбосон irts бүртгэлээр шалгагдана.
  bool kharagdakh(AuthUser? user) {
    if (_burtgeleerKharagdakh(user)) return true;
    final irts = AuthService.irtsUser;
    return irts != null && !identical(irts, user) && _burtgeleerKharagdakh(irts);
  }

  bool _burtgeleerKharagdakh(AuthUser? user) {
    if (user == null || !systemuud.containsKey(user.system)) return false;
    if (zuvkhunAdmin && !user.irtsEsekh && user.role != 'Admin') return false;
    final erkhuud = systemuud[user.system];
    if (erkhuud == null) return true;
    bool taarakh(Iterable<String> jagsaalt) => erkhuud.any(
      (zam) => jagsaalt.any((t) => t == zam || t.startsWith('$zam/')),
    );
    // 1) zevtabs-ийн "Цонхны эрх"-д байгууллагад сонгогдсон байх (мэдэгдэж байвал)
    final org = user.moduluud;
    if (org == null && zevtabsShaardlagatai) return false;
    if (org != null && !taarakh(org)) return false;
    // 2) Admin бүх сонгогдсон цонхыг харна (вэбтэй ижил)
    if (user.role == 'Admin' && (org != null || user.irtsEsekh)) return true;
    // 3) Байгууллагад zevtabs-аар идэвхжүүлсэн модуль (Ирц, Цалин, Ажил
    //    менежмент...) тухайн байгууллагын БҮХ ажилтанд харагдана — ажилтан
    //    бүрт цонх олгох шаардлагагүй. Зөвхөн удирдлагын модуль (Удирдлага)
    //    ажилтанд тухайн цонх олгогдсон байхыг шаардана.
    if (org != null && !zuvkhunAdmin) return true;
    // 4) Байгууллагын мэдээлэл ирээгүй, эсвэл удирдлагын модуль бол ажилтны цонхоор
    return taarakh(user.tsonkhniiErkhuud);
  }
}

class _HomeShellState extends State<_HomeShell> {
  int _idx = 0;
  List<String> _moduliinNeruud = const [];

  List<FsmModul> _bukhModul = const [];

  /// Доод цэсэнд таб хэвээр үлдэх үндсэн модулиуд (дарааллаар)
  static const _undsenTabuud = {'Нүүр', 'Даалгавар', 'Ирц', 'Цалин'};

  /// Нүүр хуудаснаас модуль нээх: таб байвал шилжинэ, "Цэс" дотор байвал тусдаа хуудсаар нээнэ
  void _modulNeey(String ner) {
    final i = _moduliinNeruud.indexOf(ner);
    if (i >= 0) {
      setState(() => _idx = i);
      return;
    }
    for (final m in _bukhModul) {
      if (m.ner == ner) return _modulKhuudasNeey(m);
    }
  }

  void _modulKhuudasNeey(FsmModul m) {
    final khuudas = m.tusdaaKhuudas ?? m.khuudas;
    if (!m.tolgoiKheregtei) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => khuudas));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => Scaffold(
        appBar: GradientTolgoi(garchig: m.ner),
        backgroundColor: ctx.colors.loginBackground,
        body: khuudas,
      ),
    ));
  }

  void _burtgelSoligdov() {
    if (mounted) setState(() => _idx = 0);
  }

  @override
  void dispose() {
    AuthService.burtgelOorchlogdson.removeListener(_burtgelSoligdov);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Профайлаас irts бүртгэл холбох/салгахад табууд шинэчлэгдэнэ
    AuthService.burtgelOorchlogdson.addListener(_burtgelSoligdov);
    Future.wait([
      AuthService.erkhShinechlekh(),
      AuthService.moduluudShinechlekh(),
    ]).then((_) {
      if (mounted) setState(() {});
    });
    // Анх нэвтэрсний дараа байршил, мэдэгдлийн зөвшөөрлийг тайлбартай асууна
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ZuvshuurulScreen.shaardlagatai(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = AuthService.currentUser;
    final irtsModul = FsmModul(
      Icons.how_to_reg_rounded,
      'Ирц',
      IrtsScreen(onLogout: widget.onLogout),
      systemuud: const {
        'fsm': ['/khyanalt/uilchilgee/irts'],
        'irts': ['/khyanalt/irts', '/khyanalt/chuluu'],
      },
    );
    final irtsKharagdakh = irtsModul.kharagdakh(user);
    // Ажил менежмент (FSM): FSM бүртгэлд үргэлж, irts бүртгэлд байгууллагад
    // zevtabs-ийн "Ажил менежмент" (/khyanalt/uilchilgee/...) цонх сонгогдсон
    // бөгөөд ажилтанд (эсвэл Admin) олгогдсон үед харагдана.
    const fsmSystemuud = {
      'fsm': null,
      'irts': ['/khyanalt/uilchilgee'],
    };
    final daalgavarKharagdakh =
        const FsmModul(Icons.checklist_rounded, 'Даалгавар', SizedBox(), systemuud: fsmSystemuud)
            .kharagdakh(user);
    // Цалин бүх хэрэглэгчид харагдана (эрхээс үл хамаарна)
    const tsalinModul = FsmModul(
      Icons.account_balance_wallet_outlined,
      'Цалин',
      TsalinScreen(),
      systemuud: {'fsm': null, 'irts': null},
    );
    final tsalinKharagdakh = tsalinModul.kharagdakh(user);
    // Нүүр нь хэд хэдэн модулийг холбох төв
    final nuurKhereg = irtsKharagdakh || tsalinKharagdakh || daalgavarKharagdakh;
    // Нүүр: доод цэсэнд багтаагүй модулиудыг үйлчилгээ болгон харуулна
    FsmModul nuurModul(List<(IconData, String)> busad) => FsmModul(
          Icons.home_rounded,
          'Нүүр',
          NuurScreen(
            key: ValueKey('nuur-${user?.id}'),
            irtsKharagdakh: irtsKharagdakh,
            daalgavarKharagdakh: daalgavarKharagdakh,
            tsalinKharagdakh: tsalinKharagdakh,
            busadModuluud: busad,
            onModulNeey: _modulNeey,
            onLogout: widget.onLogout,
          ),
          systemuud: const {'fsm': null, 'irts': null},
        );
    // Шинэ модуль нэмэхдээ энд нэг мөр (erkh-тэй) нэмнэ.
    final moduluud = <FsmModul>[
      if (nuurKhereg) nuurModul(const []),
      FsmModul(
        Icons.checklist_rounded,
        'Даалгавар',
        CleanerDashboardScreen(onLogout: widget.onLogout, irtsKharagdakh: irtsKharagdakh),
        systemuud: fsmSystemuud,
      ),
      irtsModul,
      const FsmModul(
        Icons.dashboard_customize_rounded,
        'Удирдлага',
        UdirdlagaScreen(),
        zuvkhunAdmin: true,
        tolgoiKheregtei: true,
        systemuud: {
          'fsm': ['/khyanalt/uilchilgee/irts'],
          'irts': [
            '/khyanalt/irts/jagsaalt',
            '/khyanalt/irts/khyanalt',
            '/khyanalt/irts/khuraangui',
          ],
        },
      ),
      tsalinModul,
      const FsmModul(Icons.calendar_today_rounded, 'Түүх', HistoryScreen(), systemuud: fsmSystemuud),
      FsmModul(
        Icons.chat_bubble_outline_rounded,
        'Чат',
        ValueListenableBuilder<Project?>(
          valueListenable: ProjectService.activeProject,
          builder: (context, Project? activeProject, _) {
            if (activeProject == null) {
              return const Scaffold(
                body: Center(child: Text('Төсөл сонгоогүй байна')),
              );
            }
            // Using a unique key forces the ChatScreen to re-mount if the project changes,
            // which re-initializes _loadMessages() and SocketService rooms.
            return ChatScreen(
              key: ValueKey(activeProject.id),
              projectId: activeProject.id,
              barilgiinId: activeProject.barilgiinId,
              baiguullagiinId: activeProject.baiguullagiinId,
              title: '${activeProject.ner} Чат',
              showBackButton: false,
            );
          },
        ),
        tusdaaKhuudas: ValueListenableBuilder<Project?>(
          valueListenable: ProjectService.activeProject,
          builder: (context, Project? activeProject, _) {
            if (activeProject == null) {
              return const Scaffold(
                body: Center(child: Text('Төсөл сонгоогүй байна')),
              );
            }
            // Using a unique key forces the ChatScreen to re-mount if the project changes,
            // which re-initializes _loadMessages() and SocketService rooms.
            return ChatScreen(
              key: ValueKey(activeProject.id),
              projectId: activeProject.id,
              barilgiinId: activeProject.barilgiinId,
              baiguullagiinId: activeProject.baiguullagiinId,
              title: '${activeProject.ner} Чат',
              showBackButton: true,
            );
          },
        ),
        systemuud: fsmSystemuud,
      ),
      const FsmModul(Icons.insights_rounded, 'Гүйцэтгэл', PerformanceScreen(), systemuud: fsmSystemuud),
    ].where((m) => m.kharagdakh(user)).toList();
    _bukhModul = moduluud;

    // Утсан дээр доод цэс 5-аас олон таб багтаахгүй: үндсэн модулиуд таб
    // хэвээр, үлдсэн нь (Удирдлага, Түүх, Чат, Гүйцэтгэл...) "Цэс" таб руу орно.
    // Өргөн дэлгэц (хажуугийн цэс) бүх модулийг шууд харуулна.
    final ortgon = MediaQuery.sizeOf(context).width >= 720;
    var tabuud = moduluud;
    if (!ortgon && moduluud.length > 5) {
      final undsen = [for (final m in moduluud) if (_undsenTabuud.contains(m.ner)) m].take(4).toList();
      final busad = [for (final m in moduluud) if (!undsen.contains(m)) m];
      final nuurtei = undsen.any((m) => m.ner == 'Нүүр');
      tabuud = nuurtei
          // "Цэс" таб байхгүй: бусад модулиуд Нүүр хуудасны "Үйлчилгээ"-нд орно
          ? [
              for (final m in undsen)
                m.ner == 'Нүүр' ? nuurModul([for (final b in busad) (b.icon, b.ner)]) : m,
            ]
          : [
              ...undsen,
              FsmModul(
                Icons.grid_view_rounded,
                'Цэс',
                _TsesKhuudas(moduluud: busad, onNeey: _modulKhuudasNeey),
              ),
            ];
    }
    _moduliinNeruud = [for (final m in tabuud) m.ner];

    if (tabuud.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: c.mutedForeground,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Танд нээлттэй цонх алга байна.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Удирдлагаасаа цонхны эрх авсны дараа дахин нэвтэрнэ үү.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: c.mutedForeground),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: widget.onLogout,
                    child: const Text('Гарах'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final idx = _idx.clamp(0, tabuud.length - 1);
    final body = IndexedStack(
      index: idx,
      children: [for (final m in tabuud) m.khuudas],
    );

    // Ганц модультай бол цэс хэрэггүй
    // AI туслах: хөвөгч товч. Өөрийн хөвөгч товчтой (Даалгавар) эсвэл доороо
    // бичих талбартай (Чат) табуудад давхцахгүйн тулд харуулахгүй.
    final aiTovch = const {'Даалгавар', 'Чат'}.contains(tabuud[idx].ner) ? null : const _AiTovch();

    if (tabuud.length == 1) return Scaffold(body: body, floatingActionButton: aiTovch);

    // iPad, Galaxy Fold (дэлгэж), хэвтээ утас: хажуугийн цэс
    if (ortgon) {
      return Scaffold(
        floatingActionButton: aiTovch,
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: idx,
                onDestinationSelected: (i) => setState(() => _idx = i),
                backgroundColor: c.cardBackground,
                labelType: NavigationRailLabelType.all,
                indicatorColor: c.brandGreen.withValues(alpha: 0.14),
                selectedIconTheme: IconThemeData(color: c.brandGreen),
                unselectedIconTheme: IconThemeData(color: c.mutedForeground),
                selectedLabelTextStyle: TextStyle(
                  color: c.brandGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: c.mutedForeground,
                  fontSize: 12,
                ),
                destinations: [
                  for (final m in tabuud)
                    NavigationRailDestination(
                      icon: Icon(m.icon),
                      label: Text(m.ner),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: c.border),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      // Доод цэсний зурвас хуудасны өнгөтэй ижил — тусдаа цагаан зурвас харагдахгүй
      backgroundColor: c.loginBackground,
      body: body,
      floatingActionButton: aiTovch,
      bottomNavigationBar: _PillNav(
        moduluud: tabuud,
        idx: idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

/// Хөвөгч капсул доод цэс: сонгосон таб руу emerald заагч гулсаж очно.
/// 5 хүртэл таб бол нэр бүгд харагдана; түүнээс олон бол зөвхөн сонгосных.
class _PillNav extends StatelessWidget {
  const _PillNav({
    required this.moduluud,
    required this.idx,
    required this.onTap,
  });
  final List<FsmModul> moduluud;
  final int idx;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = moduluud.length;
    final bugdNer = n <= 5;
    final doodZai = MediaQuery.paddingOf(context).bottom;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final khugatsaa = reduce
        ? Duration.zero
        : const Duration(milliseconds: 320);
    return Padding(
      // Капсул доод зурвас дотроо босоо төвд: дээр, доор ойролцоо ижил зай
      // (iPhone-ы home indicator капсулын доор харагдах тул бүтэн doodZai шаардлагагүй)
      padding: EdgeInsets.fromLTRB(14, 12, 14, doodZai > 0 ? (doodZai - 14).clamp(12.0, 40.0) : 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: c.cardBackground,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: c.border.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: c.brandGreen.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            // Олон табтай үед сонгосон нь 2 дахин өргөн (нэр нь багтахын тулд)
            final flexes = [
              for (var i = 0; i < n; i++) (!bugdNer && i == idx) ? 2.0 : 1.0,
            ];
            final niit = flexes.fold<double>(0, (a, b) => a + b);
            final negj = box.maxWidth / niit;
            final zuun =
                flexes.take(idx).fold<double>(0, (a, b) => a + b) * negj;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: khugatsaa,
                  curve: Curves.easeOutBack,
                  left: zuun,
                  top: 0,
                  bottom: 0,
                  width: flexes[idx] * negj,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          c.brandGreen.withValues(alpha: 0.16),
                          c.brandGreen.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        flex: (flexes[i] * 2).round(),
                        child: Semantics(
                          selected: i == idx,
                          button: true,
                          label: moduluud[i].ner,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              if (i != idx) HapticFeedback.selectionClick();
                              onTap(i);
                            },
                            child: _NavTab(
                              modul: moduluud[i],
                              songogdson: i == idx,
                              nerKharuulakh: bugdNer || i == idx,
                              bosoo: bugdNer,
                              khugatsaa: khugatsaa,
                              jijig: n == 5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.modul,
    required this.songogdson,
    required this.nerKharuulakh,
    required this.bosoo,
    required this.khugatsaa,
    required this.jijig,
  });
  final FsmModul modul;
  final bool songogdson, nerKharuulakh, bosoo, jijig;
  final Duration khugatsaa;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ungu = songogdson ? c.brandGreen : c.mutedForeground;
    final icon = AnimatedScale(
      scale: songogdson ? 1.12 : 1,
      duration: khugatsaa,
      curve: Curves.easeOutBack,
      child: Icon(modul.icon, size: 22, color: ungu),
    );
    final ner = Text(
      modul.ner,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        fontSize: jijig ? 10.5 : 11.5,
        fontWeight: FontWeight.w500,
        color: ungu,
        letterSpacing: -0.1,
      ),
    );
    if (bosoo) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 3),
          FittedBox(fit: BoxFit.scaleDown, child: ner),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        if (nerKharuulakh) ...[const SizedBox(width: 6), Flexible(child: ner)],
      ],
    );
  }
}

/// "Цэс" таб: доод цэсэнд багтаагүй модулиудыг өнгөт хавтангаар харуулна
class _TsesKhuudas extends StatelessWidget {
  const _TsesKhuudas({required this.moduluud, required this.onNeey});
  final List<FsmModul> moduluud;
  final ValueChanged<FsmModul> onNeey;

  static const _ungunuud = [
    Color(0xFFF18F02),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.loginBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Text('Бусад модулиуд', style: TextStyle(fontSize: 14, color: c.mutedForeground)),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                for (var i = 0; i < moduluud.length; i++)
                  _TsesKhavtan(modul: moduluud[i], ungu: _ungunuud[i % _ungunuud.length], onTap: () => onNeey(moduluud[i])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TsesKhavtan extends StatelessWidget {
  const _TsesKhavtan({required this.modul, required this.ungu, required this.onTap});
  final FsmModul modul;
  final Color ungu;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Color.alphaBlend(ungu.withValues(alpha: 0.10), c.cardBackground),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: ungu.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(ungu, Colors.white, 0.25)!, ungu],
                ),
              ),
              child: Icon(modul.icon, color: Colors.white, size: 22),
            ),
            const Spacer(),
            Text(modul.ner, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: c.primary)),
          ]),
        ),
      ),
    );
  }
}

/// AI туслахын хөвөгч товч (бүх үндсэн табын баруун доод буланд)
class _AiTovch extends StatelessWidget {
  const _AiTovch();
  @override
  Widget build(BuildContext context) {
    return AiTovch(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AiTuslakhScreen()),
      ),
    );
  }
}
