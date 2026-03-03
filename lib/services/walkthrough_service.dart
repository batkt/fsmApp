import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage walkthrough/onboarding state
class WalkthroughService {
  static const String _keyPrefix = 'walkthrough_';

  /// Check if a walkthrough has been completed
  static Future<bool> isCompleted(String walkthroughId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix$walkthroughId') ?? false;
  }

  /// Mark a walkthrough as completed
  static Future<void> markCompleted(String walkthroughId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$walkthroughId', true);
  }

  /// Reset all walkthroughs (for testing)
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Check if any walkthrough has been shown
  static Future<bool> hasShownAny() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    return keys.isNotEmpty;
  }
}

/// Walkthrough step definition
class WalkthroughStep {
  final String id;
  final String title;
  final String description;
  final GlobalKey targetKey;
  final WalkthroughPosition position;
  final String? screenId;

  const WalkthroughStep({
    required this.id,
    required this.title,
    required this.description,
    required this.targetKey,
    this.position = WalkthroughPosition.bottom,
    this.screenId,
  });
}

enum WalkthroughPosition { top, bottom, left, right, center }

/// Walkthrough configuration for a screen
class WalkthroughConfig {
  final String screenId;
  final List<WalkthroughStep> steps;
  final String? title;
  final String? description;

  const WalkthroughConfig({
    required this.screenId,
    required this.steps,
    this.title,
    this.description,
  });
}
