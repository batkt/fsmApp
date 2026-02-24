import 'package:flutter/material.dart';

/// Custom theme extension with all design-system colors from coloring.md
@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.brandGreen,
    required this.primary,
    required this.primaryForeground,
    required this.background,
    required this.cardBackground,
    required this.loginBackground,
    required this.secondary,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.inputBorder,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.warningOrange,
    required this.info,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.blueAccent,
    required this.lightBlue,
  });

  final Color brandGreen;
  final Color primary;
  final Color primaryForeground;
  final Color background;
  final Color cardBackground;
  final Color loginBackground;
  final Color secondary;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color inputBorder;
  final Color destructive;
  final Color success;
  final Color warning;
  final Color warningOrange;
  final Color info;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;
  final Color blueAccent;
  final Color lightBlue;

  // ── Light Mode ──
  static const light = AppColorScheme(
    brandGreen: Color(0xFF059669),
    primary: Color(0xFF0F172A),
    primaryForeground: Color(0xFFF8FAFC),
    background: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    loginBackground: Color(0xFFF5F9FC),
    secondary: Color(0xFFF1F5F9),
    muted: Color(0xFFF1F5F9),
    mutedForeground: Color(0xFF64748B),
    border: Color(0xFFE2E8F0),
    inputBorder: Color(0xFFE2E8F0),
    destructive: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    warning: Color(0xFFFACC15),
    warningOrange: Color(0xFFF97316),
    info: Color(0xFF3B82F6),
    chart1: Color(0xFFE37A4A),
    chart2: Color(0xFF2A9D8F),
    chart3: Color(0xFF264653),
    chart4: Color(0xFFE9C46A),
    chart5: Color(0xFFF4A261),
    blueAccent: Color(0xFF1E88E5),
    lightBlue: Color(0xFFE1F5FE),
  );

  // ── Dark Mode ──
  static const dark = AppColorScheme(
    brandGreen: Color(0xFF059669),
    primary: Color(0xFFF8FAFC),
    primaryForeground: Color(0xFF0F172A),
    background: Color(0xFF020817),
    cardBackground: Color(0xFF0F172A),
    loginBackground: Color(0xFF020817),
    secondary: Color(0xFF1E293B),
    muted: Color(0xFF1E293B),
    mutedForeground: Color(0xFF94A3B8),
    border: Color(0xFF1E293B),
    inputBorder: Color(0xFF1E293B),
    destructive: Color(0xFF7F1D1D),
    success: Color(0xFF2EB88A),
    warning: Color(0xFFFACC15),
    warningOrange: Color(0xFFE09333),
    info: Color(0xFF2663D9),
    chart1: Color(0xFF2663D9),
    chart2: Color(0xFF2EB88A),
    chart3: Color(0xFFE09333),
    chart4: Color(0xFFA855F7),
    chart5: Color(0xFFE03670),
    blueAccent: Color(0xFF2663D9),
    lightBlue: Color(0xFF1E293B),
  );

  @override
  AppColorScheme copyWith({
    Color? brandGreen, Color? primary, Color? primaryForeground,
    Color? background, Color? cardBackground, Color? loginBackground,
    Color? secondary, Color? muted, Color? mutedForeground,
    Color? border, Color? inputBorder, Color? destructive,
    Color? success, Color? warning, Color? warningOrange, Color? info,
    Color? chart1, Color? chart2, Color? chart3, Color? chart4,
    Color? chart5, Color? blueAccent, Color? lightBlue,
  }) {
    return AppColorScheme(
      brandGreen: brandGreen ?? this.brandGreen,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      loginBackground: loginBackground ?? this.loginBackground,
      secondary: secondary ?? this.secondary,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      inputBorder: inputBorder ?? this.inputBorder,
      destructive: destructive ?? this.destructive,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningOrange: warningOrange ?? this.warningOrange,
      info: info ?? this.info,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
      blueAccent: blueAccent ?? this.blueAccent,
      lightBlue: lightBlue ?? this.lightBlue,
    );
  }

  @override
  AppColorScheme lerp(covariant ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      brandGreen: Color.lerp(brandGreen, other.brandGreen, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      loginBackground: Color.lerp(loginBackground, other.loginBackground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningOrange: Color.lerp(warningOrange, other.warningOrange, t)!,
      info: Color.lerp(info, other.info, t)!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
      blueAccent: Color.lerp(blueAccent, other.blueAccent, t)!,
      lightBlue: Color.lerp(lightBlue, other.lightBlue, t)!,
    );
  }
}

/// Helper to access AppColorScheme from context
extension AppColorSchemeExtension on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.light;
}
