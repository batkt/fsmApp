import 'package:flutter/material.dart';
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
    List<String>? photoPaths,
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
      default:
        status = t.isOverdue ? TaskStatus.overdue : TaskStatus.pending;
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

    // Extract time from DateTime or use defaults
    final start = t.ekhlekhTsag;
    final end = t.duusakhTsag;
    final startTime = start != null
        ? TimeOfDay(hour: start.hour, minute: start.minute)
        : const TimeOfDay(hour: 9, minute: 0);
    final endTime = end != null
        ? TimeOfDay(hour: end.hour, minute: end.minute)
        : const TimeOfDay(hour: 18, minute: 0);

    // Subtasks
    final subs = t.subTasks
        .map((s) => SubTask(id: s.id, title: s.ner, isDone: s.duussan))
        .toList();

    return CleaningTask(
      id: t.id,
      title: t.ner,
      location: t.taskId,
      date: t.ekhlekhTsag ?? DateTime.now(),
      startTime: startTime,
      endTime: endTime,
      status: status,
      priority: prio,
      notes: t.tailbar,
      buildingId: t.barilgiinId,
      taskCode: t.taskId,
      projectId: t.projectId,
      subtasks: subs,
      hasPhoto: t.zurag.isNotEmpty,
      photoCount: t.zurag.length,
      photoPaths: t.zurag
          .map((z) => z.zamNer ?? z.fileNer ?? '')
          .where((path) => path.isNotEmpty)
          .toList(),
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
  TaskStatus status;
  bool hasPhoto;
  int photoCount;
  final List<String> photoPaths;

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
}

DateTime stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

List<CleaningTask> generateMockTasks() {
  return []; // No more mock tasks — everything from API now
}
