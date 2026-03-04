import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'screens/root_screen.dart';
import 'theme/app_theme.dart';
import 'services/holiday_service.dart';
import 'services/fcm_service.dart';

// Background message handler (must be top-level)
// This function must be top-level and cannot be a class method
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[FCM Background] Firebase already initialized or error: $e');
  }

  // Call the FCM service handler
  await FCMService.firebaseMessagingBackgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize FCM
    await FCMService.initialize();
  } catch (e) {
    debugPrint('[Main] Firebase initialization error: $e');
    debugPrint(
      '[Main] Continuing without Firebase - using local notifications only',
    );
    debugPrint(
      '[Main] Note: To use Firebase, you need to add google-services.json (Android) and GoogleService-Info.plist (iOS)',
    );
  }

  await HolidayService.init();
  runApp(const WorkEaseApp());
}

class WorkEaseApp extends StatelessWidget {
  const WorkEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'workEase',
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
            fontSize: Platform.isIOS ? 17 : 20, // Smaller on iOS
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            size: Platform.isIOS ? 22 : 24, // Smaller icons on iOS
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: Platform.isIOS ? 16 : 18),
          bodyMedium: TextStyle(fontSize: Platform.isIOS ? 15 : 16),
          bodySmall: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
          titleLarge: TextStyle(
            fontSize: Platform.isIOS ? 21 : 24,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontSize: Platform.isIOS ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            fontSize: Platform.isIOS ? 16 : 18,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: TextStyle(fontSize: Platform.isIOS ? 15 : 16),
          labelMedium: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
          labelSmall: TextStyle(fontSize: Platform.isIOS ? 12 : 13),
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
            color: AppColorScheme.light.primaryForeground,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
            fontSize: Platform.isIOS ? 17 : 20, // Smaller on iOS
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(
            size: Platform.isIOS ? 22 : 24, // Smaller icons on iOS
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: Platform.isIOS ? 16 : 18),
          bodyMedium: TextStyle(fontSize: Platform.isIOS ? 15 : 16),
          bodySmall: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
          titleLarge: TextStyle(
            fontSize: Platform.isIOS ? 21 : 24,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontSize: Platform.isIOS ? 18 : 20,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            fontSize: Platform.isIOS ? 16 : 18,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: TextStyle(fontSize: Platform.isIOS ? 15 : 16),
          labelMedium: TextStyle(fontSize: Platform.isIOS ? 13 : 14),
          labelSmall: TextStyle(fontSize: Platform.isIOS ? 12 : 13),
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
          contentTextStyle: TextStyle(color: AppColorScheme.dark.primary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        useMaterial3: true,
        extensions: const [AppColorScheme.dark],
      ),
      home: const RootScreen(),
    );
  }
}
