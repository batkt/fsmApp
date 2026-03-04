import 'package:flutter/material.dart';
import 'dart:io';

/// Responsive design utilities for iOS and Android
/// Scales text, icons, and spacing based on screen size and platform
class Responsive {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get device pixel ratio
  static double devicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Check if device is iPhone 14 Pro or similar (smaller screen)
  static bool isCompactDevice(BuildContext context) {
    final width = screenWidth(context);
    // iPhone 14 Pro: 393 x 852 (portrait)
    // iPhone 14 Pro Max: 430 x 932
    // Consider devices with width < 400 as compact
    return width < 400;
  }

  /// Get responsive font size multiplier
  /// iOS devices get smaller base sizes, especially compact devices
  static double fontSizeMultiplier(BuildContext context) {
    if (isAndroid) return 1.0; // Android uses default sizes

    if (isCompactDevice(context)) {
      return 0.85; // 15% smaller for compact iOS devices (iPhone 14 Pro, etc.)
    }
    return 0.9; // 10% smaller for regular iOS devices
  }

  /// Get responsive icon size multiplier
  static double iconSizeMultiplier(BuildContext context) {
    if (isAndroid) return 1.0;

    if (isCompactDevice(context)) {
      return 0.8; // 20% smaller icons for compact iOS
    }
    return 0.85; // 15% smaller icons for regular iOS
  }

  /// Get responsive spacing multiplier
  static double spacingMultiplier(BuildContext context) {
    if (isAndroid) return 1.0;

    if (isCompactDevice(context)) {
      return 0.85; // 15% less spacing for compact iOS
    }
    return 0.9; // 10% less spacing for regular iOS
  }

  /// Get responsive font size
  static double fontSize(BuildContext context, double baseSize) {
    return baseSize * fontSizeMultiplier(context);
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    return baseSize * iconSizeMultiplier(context);
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    return baseSpacing * spacingMultiplier(context);
  }

  /// Get responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final mult = spacingMultiplier(context);
    return EdgeInsets.only(
      top: (top ?? vertical ?? all ?? 0) * mult,
      bottom: (bottom ?? vertical ?? all ?? 0) * mult,
      left: (left ?? horizontal ?? all ?? 0) * mult,
      right: (right ?? horizontal ?? all ?? 0) * mult,
    );
  }

  /// Get responsive symmetric padding
  static EdgeInsets symmetricPadding(
    BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    final mult = spacingMultiplier(context);
    return EdgeInsets.symmetric(
      horizontal: (horizontal ?? 0) * mult,
      vertical: (vertical ?? 0) * mult,
    );
  }

  /// Get responsive sized box width
  static SizedBox width(BuildContext context, double width) {
    return SizedBox(width: spacing(context, width));
  }

  /// Get responsive sized box height
  static SizedBox height(BuildContext context, double height) {
    return SizedBox(height: spacing(context, height));
  }

  /// Get responsive border radius
  static double radius(BuildContext context, double baseRadius) {
    return baseRadius * spacingMultiplier(context);
  }
}

/// Extension for easy access to responsive values
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive();

  double rFontSize(double size) => Responsive.fontSize(this, size);
  double rIconSize(double size) => Responsive.iconSize(this, size);
  double rSpacing(double spacing) => Responsive.spacing(this, spacing);
  EdgeInsets rPadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) => Responsive.padding(
    this,
    all: all,
    horizontal: horizontal,
    vertical: vertical,
    top: top,
    bottom: bottom,
    left: left,
    right: right,
  );
  EdgeInsets rSymmetricPadding({double? horizontal, double? vertical}) =>
      Responsive.symmetricPadding(
        this,
        horizontal: horizontal,
        vertical: vertical,
      );
  SizedBox rWidth(double width) => Responsive.width(this, width);
  SizedBox rHeight(double height) => Responsive.height(this, height);
  double rRadius(double radius) => Responsive.radius(this, radius);
  bool get isCompactDevice => Responsive.isCompactDevice(this);
  bool get isIOS => Responsive.isIOS;
  bool get isAndroid => Responsive.isAndroid;
}
