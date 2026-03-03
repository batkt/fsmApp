import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Simple service to check for app updates.
///
/// Assumes backend exposes an endpoint like:
/// GET /app/version?platform=android|ios
/// Response example: { "latest": "1.2.3", "minSupported": "1.0.0" }
class VersionService {
  /// Current app version (update this when you release a new build).
  /// Format: major.minor.patch
  static const String currentVersion = '1.0.0';

  /// Fetch latest version info from backend.
  static Future<Map<String, dynamic>?> fetchLatest() async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final res = await ApiService.get(
        '/app/version',
        query: {'platform': platform},
      );
      if (!res.success) {
        debugPrint(
          '[VersionService] Failed to fetch latest version: ${res.message}',
        );
        return null;
      }
      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return null;
    } catch (e) {
      debugPrint('[VersionService] Error fetching latest version: $e');
      return null;
    }
  }

  /// Compare two semantic version strings.
  /// Returns:
  /// -1 if a < b, 0 if equal, 1 if a > b
  static int compareVersions(String a, String b) {
    List<int> parse(String v) =>
        v.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final va = parse(a);
    final vb = parse(b);
    final len = [va.length, vb.length].reduce((x, y) => x > y ? x : y);

    for (var i = 0; i < len; i++) {
      final pa = i < va.length ? va[i] : 0;
      final pb = i < vb.length ? vb[i] : 0;
      if (pa < pb) return -1;
      if (pa > pb) return 1;
    }
    return 0;
  }
}
