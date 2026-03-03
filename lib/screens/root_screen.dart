import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/project_service.dart';
import '../services/fcm_service.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'performance_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isLoggedIn = false;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final restored = await AuthService.restoreSession();
    if (mounted) {
      setState(() {
        _isLoggedIn = restored;
        _isCheckingSession = false;
      });
      if (restored) SocketService.connect();
    }
  }

  void _handleLoggedIn() {
    setState(() => _isLoggedIn = true);
    SocketService.connect();
  }

  void _handleLogout() async {
    SocketService.disconnect();
    // Deactivate FCM token before logout
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
        body: Center(
          child: CircularProgressIndicator(color: c.brandGreen),
        ),
      );
    }
    if (!_isLoggedIn) return LoginScreen(onLoggedIn: _handleLoggedIn);
    return _HomeShell(onLogout: _handleLogout);
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.onLogout});
  final VoidCallback onLogout;
  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pages = [
      CleanerDashboardScreen(onLogout: widget.onLogout),
      const HistoryScreen(),
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
      const PerformanceScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        backgroundColor: c.cardBackground,
        selectedItemColor: c.brandGreen,
        unselectedItemColor: c.mutedForeground,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        iconSize: 26,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rounded), label: 'Даалгавар'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded), label: 'Түүх'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Чат'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded), label: 'Гүйцэтгэл'),
        ],
      ),
    );
  }
}
