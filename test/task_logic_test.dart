import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:work_ease/models/cleaning_task.dart';
import 'package:work_ease/models/task_model.dart';

void main() {
  group('Calendar Task Filtering Logic', () {
    final now = DateTime(2026, 3, 16); // Monday
    
    test('Standard single-day task shows only on its date', () {
      final task = CleaningTask(
        id: '1',
        title: 'Single Day',
        location: 'L1',
        date: now,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        buildingId: 'B1',
      );

      expect(_mockTasksForDay([task], now).length, 1);
      expect(_mockTasksForDay([task], now.add(const Duration(days: 1))).length, 0);
    });

    test('Loop task shows on every day within range', () {
      final task = CleaningTask(
        id: '2',
        title: 'Loop Task',
        location: 'L2',
        date: now,
        ekhlekhOgnoo: now,
        duusakhOgnoo: now.add(const Duration(days: 2)), // Mon to Wed
        isLoop: true,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        buildingId: 'B1',
      );

      expect(_mockTasksForDay([task], now).length, 1); // Mon
      expect(_mockTasksForDay([task], now.add(const Duration(days: 1))).length, 1); // Tue
      expect(_mockTasksForDay([task], now.add(const Duration(days: 2))).length, 1); // Wed
      expect(_mockTasksForDay([task], now.add(const Duration(days: 3))).length, 0); // Thu
    });

    test('Full day task shows on every day within range', () {
      final task = CleaningTask(
        id: '3',
        title: 'Full Day',
        location: 'L3',
        date: now,
        ekhlekhOgnoo: now,
        duusakhOgnoo: now.add(const Duration(days: 1)), // Mon to Tue
        isDay: true,
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        buildingId: 'B1',
      );

      expect(_mockTasksForDay([task], now).length, 1); // Mon
      expect(_mockTasksForDay([task], now.add(const Duration(days: 1))).length, 1); // Tue
      expect(_mockTasksForDay([task], now.add(const Duration(days: 2))).length, 0); // Wed
    });
  });
}

// Re-implementing the logic from calendar_strip.dart for testing
List<CleaningTask> _mockTasksForDay(List<CleaningTask> tasks, DateTime day) {
  final d = stripTime(day);
  return tasks.where((t) {
    if (_same(t.date, d)) {
      print('Task "${t.title}" matches by date $d');
      return true;
    }
    if (t.isLoop || t.isDay) {
      if (t.ekhlekhOgnoo == null) return false;
      final start = stripTime(t.ekhlekhOgnoo!);
      if (t.duusakhOgnoo != null) {
        final end = stripTime(t.duusakhOgnoo!);
        bool match = (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
                     (d.isAtSameMomentAs(end) || d.isBefore(end));
        if (match) print('Task "${t.title}" (Loop/Day) matches range $start - $end for day $d');
        return match;
      } else {
        bool match = d.isAtSameMomentAs(start) || d.isAfter(start);
        if (match) print('Task "${t.title}" (Loop/Day) matches ongoing from $start for day $d');
        return match;
      }
    }
    return false;
  }).toList();
}

bool _same(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
