import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Holiday {
  final String dateStr; // YYYY-MM-DD
  final String name;

  Holiday({required this.dateStr, required this.name});

  Map<String, dynamic> toJson() => {'date': dateStr, 'name': name};
  factory Holiday.fromJson(Map<String, dynamic> json) => 
    Holiday(dateStr: json['date'] ?? json['dateStr'], name: json['name']);
}

class HolidayService {
  static final Map<int, List<Holiday>> _cache = {};
  static const _prefsKey = 'cached_holidays_';

  /// Call this when the app starts
  static Future<void> init() async {
    final now = DateTime.now();
    await loadYear(now.year);
    await loadYear(now.year + 1);
    
    // Proactively fetch if we are online and cache is empty
    _fetchAndCacheIfEmpty(now.year);
    _fetchAndCacheIfEmpty(now.year + 1);
  }

  static Future<void> loadYear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_prefsKey$year');
    if (jsonStr != null) {
      final List decoded = json.decode(jsonStr);
      _cache[year] = decoded.map((e) => Holiday.fromJson(e)).toList();
    }
  }

  static Future<void> _fetchAndCacheIfEmpty(int year) async {
    if (_cache[year] == null || _cache[year]!.isEmpty) {
      fetchHolidays(year);
    }
  }

  /// Dynamic fetch from a public API
  static Future<void> fetchHolidays(int year) async {
    try {
      final response = await http.get(
        Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/MN')
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final holidays = data.map((e) => Holiday(
          dateStr: e['date'],
          name: e['localName'] ?? e['name']
        )).toList();

        // MERGE with local verified logic to ensure multi-day holidays are correct
        final merged = _mergeWithVerified(year, holidays);

        _cache[year] = merged;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_prefsKey$year', json.encode(merged.map((e) => e.toJson()).toList()));
      }
    } catch (e) {
      debugPrint('Holiday fetch error for $year: $e');
    }
  }

  /// Returns the holiday for the given date, or null if it's not a holiday.
  static Holiday? getHoliday(DateTime date) {
    final year = date.year;
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // Check Cache first
    if (_cache.containsKey(year)) {
      for (final h in _cache[year]!) {
        if (h.dateStr == dateStr) return h;
      }
    }

    // Fallback/Bootstrap for 2025/2026 if fetch failed or hasn't run yet
    return _getHardcodedFallback(date);
  }

  static List<Holiday> _mergeWithVerified(int year, List<Holiday> apiHolidays) {
    // This ensures that even if the API is generic, we keep our specific multi-day logic
    // for known years, but allow the API to provide dates for future years.
    final result = <String, Holiday>{};
    
    // Add API ones
    for (var h in apiHolidays) {
      result[h.dateStr] = h;
    }

    // Overlay hardcoded ones (they are more accurate for MN)
    final start = DateTime(year, 1, 1);
    for (int i = 0; i < 366; i++) {
      final d = start.add(Duration(days: i));
      if (d.year != year) break;
      final h = _getHardcodedFallback(d);
      if (h != null) {
        result[h.dateStr] = h;
      }
    }

    return result.values.toList();
  }

  static Holiday? _getHardcodedFallback(DateTime date) {
    final m = date.month;
    final d = date.day;
    final ds = "${date.year}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";

    // Fixed annual holidays
    if (m == 1 && d == 1) return Holiday(dateStr: ds, name: 'Шинэ жил');
    if (m == 3 && d == 8) return Holiday(dateStr: ds, name: 'Олон улсын эмэгтэйчүүдийн баяр');
    if (m == 6 && d == 1) return Holiday(dateStr: ds, name: 'Эх үрсийн баяр');
    if (m == 7 && (d >= 11 && d <= 15)) return Holiday(dateStr: ds, name: 'Наадам');
    if (m == 11 && d == 26) return Holiday(dateStr: ds, name: 'Бүгд найрамдах улс тунхагласан өдөр');
    if (m == 12 && d == 29) return Holiday(dateStr: ds, name: 'Үндэсний эрх чөлөө, тусгаар тогтнолоо сэргээсний баяр');

    // 2025 Movable
    if (date.year == 2025) {
      if (m == 2 && d == 28) return Holiday(dateStr: ds, name: 'Битүүн');
      if (m == 3 && (d >= 1 && d <= 3)) return Holiday(dateStr: ds, name: 'Цагаан сар');
      if (m == 6 && d == 11) return Holiday(dateStr: ds, name: 'Бурхан багшийн их дүйчин өдөр');
      if (m == 11 && d == 21) return Holiday(dateStr: ds, name: 'Чингис хааны мэндэлсэн өдөр');
    }
    
    // 2026 Movable
    if (date.year == 2026) {
      if (m == 2 && d == 16) return Holiday(dateStr: ds, name: 'Битүүн');
      if (m == 2 && (d >= 17 && d <= 19)) return Holiday(dateStr: ds, name: 'Цагаан сар');
      if (m == 5 && d == 31) return Holiday(dateStr: ds, name: 'Бурхан багшийн их дүйчин өдөр');
      if (m == 11 && d == 10) return Holiday(dateStr: ds, name: 'Чингис хааны мэндэлсэн өдөр');
    }

    return null;
  }
}
