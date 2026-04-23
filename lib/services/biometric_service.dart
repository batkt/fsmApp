import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences
const _kBiometricEnabled = 'biometric_enabled';     // true/false
const _kBiometricAsked = 'biometric_asked';         // true if user was asked

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics
  Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Check if we already asked the user about biometric
  Future<bool> wasAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricAsked) ?? false;
  }

  /// Check if biometric is enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  /// Save user's choice (enable/disable) and mark as asked
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, enabled);
    await prefs.setBool(_kBiometricAsked, true);
  }

  /// Mark the user as having been asked (even if they said no)
  Future<void> markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricAsked, true);
  }

  /// Authenticate with biometrics — fully Mongolian prompts
  Future<bool> authenticate() async {
    try {
      final isIOS = Platform.isIOS;
      return await _auth.authenticate(
        localizedReason: isIOS ? 'Face ID-аар нэвтэрнэ үү' : 'Хурууны хээгээр нэвтэрнэ үү',
        authMessages: const [
          AndroidAuthMessages(
            biometricHint: 'Хурууны хээгээр баталгаажуулна уу',
            biometricNotRecognized: 'Хурууны хээ таниагүй. Дахин оролдоно уу.',
            biometricRequiredTitle: 'Хурууны хээ шаардлагатай',
            biometricSuccess: 'Амжилттай баталгаажлаа',
            cancelButton: 'Болих',
            deviceCredentialsRequiredTitle: 'Төхөөрөмжийн нууц үг шаардлагатай',
            deviceCredentialsSetupDescription: 'Төхөөрөмжийн нууц үг тохируулна уу',
            goToSettingsButton: 'Тохиргоо руу очих',
            goToSettingsDescription: 'Хурууны хээ тохируулагдаагүй байна. Тохиргоо руу очиж тохируулна уу.',
            signInTitle: 'Нэвтрэх баталгаажуулалт',
          ),
          IOSAuthMessages(
            cancelButton: 'Болих',
            goToSettingsButton: 'Тохиргоо руу очих',
            goToSettingsDescription: 'Face ID тохируулагдаагүй байна.',
            lockOut: 'Face ID түгжигдсэн. Дахин оролдохын тулд төхөөрөмжийн нууц үг оруулна уу.',
            localizedFallbackTitle: 'Нууц үг оруулах',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
