import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cleaning_task.dart';
import '../models/notification_model.dart';

class WidgetService {
  static const _channel = MethodChannel('com.example.fsmapp/widget');

  /// Update the task home screen widget with ALL tasks for today
  static Future<void> updateWidget(List<CleaningTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final total = tasks.length;
    final completed = tasks.where(
        (t) => t.status == TaskStatus.completed).length;

    await prefs.setInt('widget_total_tasks', total);
    await prefs.setInt('widget_completed_tasks', completed);

    // Write ALL tasks (not just 3)
    for (int i = 0; i < total; i++) {
      final t = tasks[i];
      await prefs.setString('widget_task${i+1}_title', t.title);
      await prefs.setString('widget_task${i+1}_time', t.timeRange);
      await prefs.setInt('widget_task${i+1}_status', t.status.index);
      await prefs.setString('widget_task${i+1}_id', t.id);
    }

    try {
      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }

  /// Update the notification widget with ALL notifications
  static Future<void> updateNotificationWidget(
      List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();

    final unread = notifications.where((n) => !n.isRead).length;
    await prefs.setInt('widget_notif_count', unread);
    await prefs.setInt('widget_notif_total', notifications.length);

    String iconFor(NotifType type) {
      switch (type) {
        case NotifType.task: return '📋';
        case NotifType.alert: return '⚠️';
        case NotifType.success: return '✅';
        case NotifType.info: return '📢';
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
      await prefs.setString('widget_notif${i+1}_title', n.title);
      await prefs.setString('widget_notif${i+1}_body', n.body);
      await prefs.setString('widget_notif${i+1}_icon', iconFor(n.type));
      await prefs.setString('widget_notif${i+1}_time', timeAgo(n.time));
    }

    try {
      await _channel.invokeMethod('updateNotificationWidget');
    } catch (_) {}
  }

  /// Read back widget state changes (user tapped Start/Finish on widget)
  static Future<Map<String, TaskStatus>> readWidgetChanges(
      List<CleaningTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final changes = <String, TaskStatus>{};

    for (int i = 0; i < tasks.length; i++) {
      final widgetStatus = prefs.getInt('widget_task${i+1}_status') ?? 0;
      final taskStatus = tasks[i].status.index;

      if (widgetStatus != taskStatus) {
        final id = prefs.getString('widget_task${i+1}_id') ?? '';
        if (id.isNotEmpty) {
          changes[id] = TaskStatus.values[widgetStatus.clamp(0, 2)];
        }
      }
    }

    return changes;
  }
}
