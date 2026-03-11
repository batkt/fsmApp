import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _fontSizeKey = 'font_size_factor';
  static const String _themeModeKey = 'theme_mode';
  
  double _fontSizeFactor = 1.0;
  ThemeMode _themeMode = ThemeMode.system;

  double get fontSizeFactor => _fontSizeFactor;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSizeFactor = prefs.getDouble(_fontSizeKey) ?? 1.0;
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    notifyListeners();
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, factor);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }
}

