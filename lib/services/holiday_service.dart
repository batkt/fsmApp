import 'package:flutter/material.dart';

class Holiday {
  final String name;
  final String description;
  Holiday({required this.name, this.description = ''});
}

class HolidayService {
  /// Returns the holiday for the given date, or null if it's not a holiday.
  static Holiday? getHoliday(DateTime date) {
    final m = date.month;
    final d = date.day;

    // Fixed annual holidays
    if (m == 1 && d == 1) return Holiday(name: 'Шинэ жил');
    if (m == 3 && d == 8) return Holiday(name: 'Олон улсын эмэгтэйчүүдийн баяр');
    if (m == 6 && d == 1) return Holiday(name: 'Эх үрсийн баяр');
    if (m == 7 && (d >= 11 && d <= 15)) return Holiday(name: 'Наадам');
    if (m == 11 && d == 26) return Holiday(name: 'Бүгд найрамдах улс тунхагласан өдөр');
    if (m == 12 && d == 29) return Holiday(name: 'Үндэсний эрх чөлөө, тусгаар тогтнолоо сэргээсний баяр');

    // 2025 Movable Holidays
    if (date.year == 2025) {
      // Bituun & Tsagaan Sar (Feb 28 - Mar 3)
      if (m == 2 && d == 28) return Holiday(name: 'Битүүн');
      if (m == 3 && (d >= 1 && d <= 3)) return Holiday(name: 'Цагаан сар');
      // Buddha Day
      if (m == 6 && d == 11) return Holiday(name: 'Бурхан багшийн их дүйчин өдөр');
      // Chinggis Khaan's Birthday (National Pride Day)
      if (m == 11 && d == 21) return Holiday(name: 'Чингис хааны мэндэлсэн өдөр');
    }
    
    // 2026 Movable Holidays
    if (date.year == 2026) {
      // Bituun & Tsagaan Sar (Feb 16 - Feb 19)
      if (m == 2 && d == 16) return Holiday(name: 'Битүүн');
      if (m == 2 && (d >= 17 && d <= 19)) return Holiday(name: 'Цагаан сар');
      // Buddha Day
      if (m == 5 && d == 31) return Holiday(name: 'Бурхан багшийн их дүйчин өдөр');
      // Chinggis Khaan's Birthday (National Pride Day)
      if (m == 11 && d == 10) return Holiday(name: 'Чингис хааны мэндэлсэн өдөр');
    }

    return null;
  }
}
