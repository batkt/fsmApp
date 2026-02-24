import 'package:flutter/material.dart';

import 'screens/root_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CleanerApp());
}

class CleanerApp extends StatelessWidget {
  const CleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Цэвэрлэгээний апп',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // follows device setting
      // ── Light Theme ──
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColorScheme.light.brandGreen,
          primary: AppColorScheme.light.brandGreen,
          secondary: AppColorScheme.light.secondary,
          error: AppColorScheme.light.destructive,
          surface: AppColorScheme.light.background,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColorScheme.light.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorScheme.light.background,
          foregroundColor: AppColorScheme.light.primary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColorScheme.light.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        dividerColor: AppColorScheme.light.border,
        cardColor: AppColorScheme.light.cardBackground,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColorScheme.light.background,
          selectedItemColor: AppColorScheme.light.brandGreen,
          unselectedItemColor: AppColorScheme.light.mutedForeground,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorScheme.light.primary,
          contentTextStyle: TextStyle(
              color: AppColorScheme.light.primaryForeground),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        useMaterial3: true,
        extensions: const [AppColorScheme.light],
      ),
      // ── Dark Theme ──
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColorScheme.dark.brandGreen,
          primary: AppColorScheme.dark.brandGreen,
          secondary: AppColorScheme.dark.secondary,
          error: AppColorScheme.dark.destructive,
          surface: AppColorScheme.dark.background,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColorScheme.dark.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColorScheme.dark.background,
          foregroundColor: AppColorScheme.dark.primary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColorScheme.dark.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        dividerColor: AppColorScheme.dark.border,
        cardColor: AppColorScheme.dark.cardBackground,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColorScheme.dark.cardBackground,
          selectedItemColor: AppColorScheme.dark.brandGreen,
          unselectedItemColor: AppColorScheme.dark.mutedForeground,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColorScheme.dark.secondary,
          contentTextStyle: TextStyle(
              color: AppColorScheme.dark.primary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        useMaterial3: true,
        extensions: const [AppColorScheme.dark],
      ),
      home: const RootScreen(),
    );
  }
}
