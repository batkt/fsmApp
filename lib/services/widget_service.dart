import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cleaning_task.dart';
import '../models/notification_model.dart';

// Helper to check if platform is iOS (web-compatible)
bool get _isIOS {
  return defaultTargetPlatform == TargetPlatform.iOS;
}

class WidgetService {
  static const _channel = MethodChannel('com.batkt.workease/widget');
  static const _liveActivityChannel = MethodChannel('com.batkt.workease/live_activity');

  /// Update the task home screen widget with ALL tasks for today
  static Future<void> updateWidget(List<CleaningTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final total = tasks.length;
    final completed = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;

    await prefs.setInt('widget_total_tasks', total);
    await prefs.setInt('widget_completed_tasks', completed);

    // Write ALL tasks (not just 3)
    for (int i = 0; i < total; i++) {
      final t = tasks[i];
      await prefs.setString('widget_task${i + 1}_title', t.title);
      await prefs.setString('widget_task${i + 1}_time', t.timeRange);
      await prefs.setInt('widget_task${i + 1}_status', t.status.index);
      await prefs.setString('widget_task${i + 1}_id', t.id);
    }

    // On iOS, also write to App Group UserDefaults for widget access
    if (_isIOS) {
      await _writeToAppGroup(prefs);
    }

    try {
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      // Silently fail if platform doesn't support widgets
      debugPrint('[WidgetService] Failed to update widget: $e');
    }
  }

  /// Update the notification widget with ALL notifications
  static Future<void> updateNotificationWidget(
    List<AppNotification> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final unread = notifications.where((n) => !n.isRead).length;
    await prefs.setInt('widget_notif_count', unread);
    await prefs.setInt('widget_notif_total', notifications.length);

    String iconFor(NotifType type) {
      switch (type) {
        case NotifType.task:
        case NotifType.taskCreated:
        case NotifType.taskUpdated:
          return '📋';
        case NotifType.taskStarted:
          return '▶️';
        case NotifType.taskCompleted:
          return '✅';
        case NotifType.taskExpired:
          return '⏰';
        case NotifType.taskReset:
          return '🔄';
        case NotifType.alert:
        case NotifType.assignment:
        case NotifType.reminder:
          return '⚠️';
        case NotifType.info:
        case NotifType.projectCreated:
        case NotifType.projectUpdated:
        case NotifType.chatMessage:
          return '📢';
        case NotifType.success:
          return '✅';
        case NotifType.medegdel:
          return '🔔';
      }
    }

    String timeAgo(DateTime t) {
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 1) return 'одоо';
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
      if (diff.inHours < 24) return '${diff.inHours} цаг';
      return '${diff.inDays} өдөр';
    }

    for (int i = 0; i < notifications.length; i++) {
      final n = notifications[i];
      await prefs.setString('widget_notif${i + 1}_title', n.title);
      await prefs.setString('widget_notif${i + 1}_body', n.body);
      await prefs.setString('widget_notif${i + 1}_icon', iconFor(n.type));
      await prefs.setString('widget_notif${i + 1}_time', timeAgo(n.time));
    }

    // On iOS, also write to App Group UserDefaults for widget access
    if (_isIOS) {
      await _writeToAppGroup(prefs);
    }

    try {
      await _channel.invokeMethod('updateNotificationWidget');
    } catch (e) {
      // Silently fail if platform doesn't support widgets
      debugPrint('[WidgetService] Failed to update notification widget: $e');
    }
  }

  /// Start Live Activity for a task
  static Future<void> startTaskActivity(CleaningTask task) async {
    if (!_isIOS) return;
    try {
      await _liveActivityChannel.invokeMethod('startTaskActivity', {
        'taskId': task.id,
        'taskCode': task.taskCode,
        'taskTitle': task.title,
        'elapsedTime': task.formattedElapsedTime,
        'progress': (task.progressPercentage ?? 0 * 100).toInt(),
        'status': 'Явагдаж буй',
      });
    } catch (e) {
      debugPrint('[WidgetService] Error starting Live Activity: $e');
    }
  }

  /// Update Live Activity progress
  static Future<void> updateTaskActivity(CleaningTask task) async {
    if (!_isIOS) return;
    try {
      await _liveActivityChannel.invokeMethod('updateTaskActivity', {
        'elapsedTime': task.formattedElapsedTime,
        'progress': (task.progressPercentage ?? 0 * 100).toInt(),
        'status': task.status == TaskStatus.completed ? 'Дууссан' : 'Явагдаж буй',
      });
    } catch (e) {
      debugPrint('[WidgetService] Error updating Live Activity: $e');
    }
  }

  /// End Live Activity
  static Future<void> endTaskActivity() async {
    if (!_isIOS) return;
    try {
      await _liveActivityChannel.invokeMethod('endTaskActivity');
    } catch (e) {
      debugPrint('[WidgetService] Error ending Live Activity: $e');
    }
  }

  /// Read back widget state changes (user tapped Start/Finish on widget)
  static Future<Map<String, TaskStatus>> readWidgetChanges(
    List<CleaningTask> tasks,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final changes = <String, TaskStatus>{};

    for (int i = 0; i < tasks.length; i++) {
      final widgetStatus = prefs.getInt('widget_task${i + 1}_status') ?? 0;
      final taskStatus = tasks[i].status.index;

      if (widgetStatus != taskStatus) {
        final id = prefs.getString('widget_task${i + 1}_id') ?? '';
        if (id.isNotEmpty) {
          changes[id] = TaskStatus.values[widgetStatus.clamp(0, 3)];
        }
      }
    }

    return changes;
  }
  
  /// Write SharedPreferences data to iOS App Group UserDefaults
  /// This allows widgets to access the data
  static Future<void> _writeToAppGroup(SharedPreferences prefs) async {
    try {
      // Use platform channel to write to App Group UserDefaults
      await _channel.invokeMethod('writeToAppGroup', {
        'keys': prefs.getKeys().toList(),
        'data': _extractPreferencesData(prefs),
      });
    } catch (e) {
      debugPrint('[WidgetService] Failed to write to App Group: $e');
    }
  }
  
  /// Extract all relevant widget data from SharedPreferences
  static Map<String, dynamic> _extractPreferencesData(SharedPreferences prefs) {
    final data = <String, dynamic>{};
    final keys = prefs.getKeys();
    
    // Only copy widget-related keys
    for (final key in keys) {
      if (key.startsWith('widget_')) {
        final value = prefs.get(key);
        if (value != null) {
          data[key] = value;
        }
      }
    }
    
    return data;
  }
}
