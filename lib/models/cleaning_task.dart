import 'package:flutter/material.dart';
import '../services/timezone_service.dart';
import 'task_model.dart';

enum TaskStatus { pending, inProgress, completed, overdue }

enum TaskPriority { high, medium, low }

class SubTask {
  SubTask({required this.id, required this.title, this.isDone = false});
  final String id;
  final String title;
  bool isDone;
}

class CleaningTask {
  CleaningTask({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = TaskStatus.pending,
    this.hasPhoto = false,
    this.priority = TaskPriority.medium,
    this.floor = '',
    this.notes = '',
    this.supervisor = '',
    this.estimatedMinutes = 0,
    this.subtasks = const [],
    this.photoCount = 0,
    required this.buildingId,
    this.taskCode = '',
    this.projectId = '',
    this.baiguullagiinId = '',
    List<String>? photoPaths,
    this.ekhlekhTsag,
    this.duusakhTsag,
    this.startedAtLocal,
    this.hariutsagchZurag = const [],
    this.ajiltanZurag = const [],
    this.ajiltanTsag = const [],
    this.baraa = const [],
    this.completedAt,
    this.ekhlekhOgnoo,
    this.duusakhOgnoo,
    this.isDay = false,
    this.isLoop = false,
    this.createdAt,
  }) : photoPaths = photoPaths ?? [];

  /// Convert an API task to a CleaningTask for the UI.
  factory CleaningTask.fromApi(ApiTask t) {
    // Map API status → UI enum
    TaskStatus status;
    switch (t.tuluv) {
      case 'khiigdej bui':
        status = TaskStatus.inProgress;
        break;
      case 'duussan':
        status = TaskStatus.completed;
        break;
      case 'shalga':
        status = TaskStatus.inProgress;
        break;
      case 'khugatsaa khetersen':
        status = TaskStatus.overdue;
        break;
      case 'shine':
      default:
        status = TaskStatus.pending;
        break;
    }

    // SPECIAL LOGIC FOR LOOPS/MULTI-DAY: 
    // If the task status is "In Progress" but there's NO log for the current/selected day 
    // for this specific worker, treat it as "Pending" for this instance/day.
    if (status == TaskStatus.inProgress && (t.isLoop || t.ekhlekhOgnoo != t.duusakhOgnoo)) {
      final now = TimezoneService.nowMongolia();
      final hasLogToday = t.ajiltanTsag.any((log) {
        final logDate = TimezoneService.toMongoliaTime(log.ekhlekhTsag.toUtc());
        return logDate.year == now.year && logDate.month == now.month && logDate.day == now.day && log.duusakhTsag == null;
      });
      if (!hasLogToday) status = TaskStatus.pending;
    }

    // Map API priority → UI enum
    TaskPriority prio;
    switch (t.zereglel) {
      case 'nen yaraltai':
        prio = TaskPriority.high;
        break;
      case 'yaraltai':
        prio = TaskPriority.high;
        break;
      case 'baga':
        prio = TaskPriority.low;
        break;
      default:
        prio = TaskPriority.medium;
    }

    // Extract time from DateTime (convert from UTC to Mongolia time) or use defaults
    final utcStart = t.ekhlekhTsag;
    final utcEnd = t.duusakhTsag;
    final start = utcStart != null
        ? TimezoneService.toMongoliaTime(utcStart.toUtc())
        : null;
    final end = utcEnd != null
        ? TimezoneService.toMongoliaTime(utcEnd.toUtc())
        : null;

    final startTime = t.isDay 
        ? const TimeOfDay(hour: 0, minute: 0)
        : (start != null
            ? TimeOfDay(hour: start.hour, minute: start.minute)
            : const TimeOfDay(hour: 9, minute: 0));
    final endTime = t.isDay 
        ? const TimeOfDay(hour: 23, minute: 59)
        : (end != null
            ? TimeOfDay(hour: end.hour, minute: end.minute)
            : const TimeOfDay(hour: 18, minute: 0));

    // Subtasks
    final subs = t.subTasks
        .map((s) => SubTask(id: s.id, title: s.ner, isDone: s.duussan))
        .toList();

    // Use Mongolia time for the task date (so calendar & filters are correct)
    final date = start ?? TimezoneService.nowMongolia();

    return CleaningTask(
      id: t.id,
      title: t.ner,
      location: t.bairshil ?? '',
      floor: t.davkhar ?? '',
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status,
      priority: prio,
      notes: t.tailbar,
      buildingId: t.barilgiinId,
      taskCode: t.taskId,
      projectId: t.projectId,
      baiguullagiinId: t.baiguullagiinId,
      subtasks: subs,
      // Combine all image types for hasPhoto check
      hasPhoto:
          t.zurag.isNotEmpty ||
          t.hariutsagchZurag.isNotEmpty ||
          t.ajiltanZurag.isNotEmpty,
      // Total count of all images
      photoCount:
          t.zurag.length + t.hariutsagchZurag.length + t.ajiltanZurag.length,
      // Legacy zurag field (for backward compatibility) - treat as employee photos
      photoPaths: t.zurag
          .map((z) => z.zamNer ?? z.fileNer ?? '')
          .where((path) => path.isNotEmpty)
          .toList(),
      // Store separate image types
      hariutsagchZurag: t.hariutsagchZurag,
      ajiltanZurag: t.ajiltanZurag,
      // Store raw ajiltan tsag data (converted to Mongolia time)
      ajiltanTsag: t.ajiltanTsag.map((entry) => AjiltanTsag(
        ajiltniiId: entry.ajiltniiId,
        ekhlekhTsag: TimezoneService.toMongoliaTime(entry.ekhlekhTsag.toUtc()),
        duusakhTsag: entry.duusakhTsag != null 
            ? TimezoneService.toMongoliaTime(entry.duusakhTsag!.toUtc()) 
            : null,
        tsagMinute: entry.tsagMinute,
        tailbar: entry.tailbar,
        ognoo: entry.ognoo != null 
            ? TimezoneService.toMongoliaTime(entry.ognoo!.toUtc()) 
            : null,
      )).toList(),
      // Store baraa items
      baraa: t.baraa,
      // Store Mongolia time for start/end for duration & progress calculations
      ekhlekhTsag: start,
      duusakhTsag: end,
      completedAt: t.duussanOgnoo != null 
          ? TimezoneService.toMongoliaTime(t.duussanOgnoo!.toUtc())
          : null,
      ekhlekhOgnoo: t.ekhlekhOgnoo != null 
          ? TimezoneService.toMongoliaTime(t.ekhlekhOgnoo!.toUtc()) 
          : null,
      duusakhOgnoo: t.duusakhOgnoo != null 
          ? TimezoneService.toMongoliaTime(t.duusakhOgnoo!.toUtc()) 
          : null,
      isDay: t.isDay,
      isLoop: t.isLoop,
      createdAt: t.createdAt != null
          ? TimezoneService.toMongoliaTime(t.createdAt!.toUtc())
          : null,
    );
  }

  final String id;
  final String title;
  final String location;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TaskPriority priority;
  final String floor;
  final String notes;
  final String supervisor;
  final int estimatedMinutes;
  final List<SubTask> subtasks;
  final String buildingId;
  final String taskCode;
  final String projectId;
  final String baiguullagiinId;
  final DateTime? ekhlekhTsag;
  final DateTime? duusakhTsag;
  // Local-only start time when user taps "Эхлэх" in the app.
  // Used so progress starts from 0% at the moment of starting.
  DateTime? startedAtLocal;
  TaskStatus status;
  bool hasPhoto;
  int photoCount;
  final List<String> photoPaths; // Employee-uploaded photos (local paths)
  final List<TaskZurag> hariutsagchZurag; // Original images from task creator
  final List<TaskZurag> ajiltanZurag; // Images uploaded by employees
  List<AjiltanTsag> ajiltanTsag; // Time tracking entries
  final List<Baraa> baraa; // Items/materials assigned to the task
  final DateTime? completedAt;
  final DateTime? ekhlekhOgnoo;
  final DateTime? duusakhOgnoo;
  final bool isDay;
  final bool isLoop;
  final DateTime? createdAt;

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    return subtasks.where((s) => s.isDone).length / subtasks.length;
  }

  int get subtasksDone => subtasks.where((s) => s.isDone).length;

  /// Formatted time range string
  String get timeRange {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} - ${fmt(endTime)}';
  }

  /// Calculate duration in minutes (per day for loops, or total for single tasks)
  int? get calculatedDurationMinutes {
    if (isDay) return 1440;
    
    if (isLoop) {
      // Loop tasks should show budget per day
      final startMin = startTime.hour * 60 + startTime.minute;
      final endMin = endTime.hour * 60 + endTime.minute;
      return (endMin >= startMin) ? (endMin - startMin) : 0;
    }
    
    if (ekhlekhTsag == null || duusakhTsag == null) return null;
    final duration = duusakhTsag!.difference(ekhlekhTsag!);
    return duration.inMinutes;
  }

  /// Format duration as a human-readable string
  String get formattedDuration {
    final minutes = calculatedDurationMinutes;
    if (minutes == null) return 'Тооцоолох боломжгүй';

    if (minutes < 60) {
      return '$minutes мин';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours цаг';
      } else {
        return '$hours цаг $remainingMinutes мин';
      }
    }
  }

  /// Calculate elapsed time in seconds for precise display
  int get elapsedSeconds {
    final bool isCompl = status == TaskStatus.completed;
    final bool isProg = status == TaskStatus.inProgress;

    if (isCompl || isProg) {
      if (ajiltanTsag.isNotEmpty) {
        int totalSeconds = 0;
        for (final tsag in ajiltanTsag) {
          // For loops, only count logs from this specific day
          if (isLoop) {
            final logDate = tsag.ekhlekhTsag;
            if (logDate.year != date.year || 
                logDate.month != date.month || 
                logDate.day != date.day) {
              continue;
            }
          }

          if (tsag.duusakhTsag != null) {
            final diff = tsag.duusakhTsag!.difference(tsag.ekhlekhTsag).inSeconds;
            if (diff > 0) totalSeconds += diff;
          } else if (tsag.tsagMinute != null && tsag.tsagMinute! > 0) {
            totalSeconds += tsag.tsagMinute! * 60;
          } else if (isProg && tsag.duusakhTsag == null) {
            // Include active session
            final diff = TimezoneService.nowMongolia().difference(tsag.ekhlekhTsag).inSeconds;
            if (diff > 0) totalSeconds += diff;
          }
        }
        return totalSeconds < 0 ? 0 : totalSeconds;
      }
      return 0;
    }

    return 0;
  }

  /// Format elapsed time as HH:mm:ss
  String get formattedElapsedHMS {
    final seconds = elapsedSeconds;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Calculate elapsed time in minutes
  /// Returns elapsed time from ekhlekhTsag to now (if in progress) or to duusakhTsag (if completed)
  int? get elapsedMinutes => (elapsedSeconds / 60.0).round();

  /// Calculate progress percentage (0.0 to 1.0)
  /// Returns null if cannot calculate
  double? get progressPercentage {
    final totalSecs = (calculatedDurationMinutes ?? 0) * 60;
    final elapsedSecs = elapsedSeconds;

    if (totalSecs == 0) return null; // Changed from `elapsedSecs == null` to `totalSecs == 0`

    // Cap at 100%
    return (elapsedSecs / totalSecs).clamp(0.0, 1.0);
  }

  /// Format elapsed time as human-readable string
  String get formattedElapsedTime {
    final minutes = elapsedMinutes;
    if (minutes == null) return '0 мин';

    if (minutes < 60) {
      return '$minutes мин';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours цаг';
      } else {
        return '$hours цаг $remainingMinutes мин';
      }
    }
  }

  /// Check if the task is active on a given day
  bool isOnDay(DateTime day) {
    final checkDay = stripTime(day);
    
    // Fall back through various possible date fields
    final start = ekhlekhOgnoo ?? ekhlekhTsag ?? date;
    final end = duusakhOgnoo ?? duusakhTsag ?? date;
    
    final taskStart = stripTime(start);
    final taskEnd = stripTime(end);
    
    return (checkDay.isAtSameMomentAs(taskStart) || checkDay.isAfter(taskStart)) &&
           (checkDay.isAtSameMomentAs(taskEnd) || checkDay.isBefore(taskEnd));
  }
}

DateTime stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

List<CleaningTask> generateMockTasks() {
  return []; // No more mock tasks — everything from API now
}
