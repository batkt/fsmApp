/// Timezone utility service for Mongolia (UTC+8)
class TimezoneService {
  /// Mongolia timezone offset in hours (UTC+8)
  static const int mongoliaOffsetHours = 8;

  /// Convert a DateTime (assumed to be in UTC) to Mongolia time (UTC+8)
  static DateTime toMongoliaTime(DateTime utcDateTime) {
    return utcDateTime.add(Duration(hours: mongoliaOffsetHours));
  }

  /// Get current time in Mongolia timezone
  static DateTime nowMongolia() {
    // DateTime.now() returns local device time
    // We need to convert it to UTC first, then add Mongolia offset
    final now = DateTime.now().toUtc();
    return toMongoliaTime(now);
  }

  /// Format time as HH:mm in Mongolia timezone
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    // If the DateTime is in UTC (from API), convert to Mongolia time
    // If it's not UTC, it's likely a local message - use it as-is (it's already in device time)
    // But we want to display in Mongolia time, so we need to:
    // 1. If UTC: add 8 hours
    // 2. If not UTC: treat it as if it were UTC and add 8 hours (since local messages are temporary)
    DateTime mongoliaTime;
    if (dateTime.isUtc) {
      // From API - UTC, convert to Mongolia
      mongoliaTime = toMongoliaTime(dateTime);
    } else {
      // Local message - treat as UTC and convert to Mongolia
      // This ensures consistent display regardless of device timezone
      mongoliaTime = toMongoliaTime(dateTime.toUtc());
    }

    return '${mongoliaTime.hour.toString().padLeft(2, '0')}:${mongoliaTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format date and time as a string in Mongolia timezone
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    DateTime mongoliaTime;
    if (dateTime.isUtc) {
      mongoliaTime = toMongoliaTime(dateTime);
    } else {
      mongoliaTime = toMongoliaTime(dateTime.toUtc());
    }

    return '${mongoliaTime.year}-${mongoliaTime.month.toString().padLeft(2, '0')}-${mongoliaTime.day.toString().padLeft(2, '0')} '
        '${mongoliaTime.hour.toString().padLeft(2, '0')}:${mongoliaTime.minute.toString().padLeft(2, '0')}';
  }
}
