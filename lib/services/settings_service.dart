import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _fontSizeKey = 'font_size_factor';
  double _fontSizeFactor = 1.0;

  double get fontSizeFactor => _fontSizeFactor;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSizeFactor = prefs.getDouble(_fontSizeKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, factor);
    notifyListeners();
  }
}
