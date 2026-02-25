import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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

  void _handleLoggedIn() => setState(() => _isLoggedIn = true);
  void _handleLogout() => setState(() => _isLoggedIn = false);

  @override
  Widget build(BuildContext context) {
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
      const PerformanceScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        backgroundColor: c.cardBackground,
        selectedItemColor: c.brandGreen,
        unselectedItemColor: c.mutedForeground,
        selectedFontSize: 14,
        unselectedFontSize: 13,
        iconSize: 28,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.checklist_rounded), label: 'Даалгавар'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded), label: 'Түүх'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded), label: 'Гүйцэтгэл'),
        ],
      ),
    );
  }
}
