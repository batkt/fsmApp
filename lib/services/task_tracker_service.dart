import 'dart:io';
import 'package:flutter/services.dart';

/// Bridge to native Android foreground service and iOS Live Activity (Dynamic Island)
/// that tracks current task (Явц).
class TaskTrackerService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.fsmapp/task_tracker',
  );

  static const MethodChannel _liveActivityChannel = MethodChannel(
    'com.example.fsmapp/live_activity',
  );

  /// Start tracking a task on Android (shows ongoing notification / Samsung chip)
  /// or iOS (shows Live Activity / Dynamic Island).
  static Future<void> startTask({
    required String taskId,
    required String code,
    required String title,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('start', {
          'taskId': taskId,
          'code': code,
          'title': title,
        });
      } catch (e) {
        // Ignore if not implemented
      }
    } else if (Platform.isIOS) {
      // Start Live Activity for Dynamic Island
      try {
        await _liveActivityChannel.invokeMethod('startTaskActivity', {
          'taskId': taskId,
          'taskCode': code,
          'taskTitle': title,
          'elapsedTime': '00:00:00',
          'progress': 0,
          'status': 'Явагдаж буй',
        });
      } catch (e) {
        // Ignore if Live Activities not available (iOS < 16.1 or not enabled)
      }
    }
  }

  /// Start live update tracking (alias for startTask for backward compatibility).
  static Future<void> startLiveUpdate({
    required String taskId,
    required String code,
    required String title,
  }) async {
    return startTask(taskId: taskId, code: code, title: title);
  }

  /// Update live progress for the current task.
  /// [progress] should be 0-100 representing completion percentage.
  /// [elapsedSeconds] should be the elapsed time in seconds.
  static Future<void> updateLiveProgress({
    required int progress,
    required int elapsedSeconds,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('updateLiveProgress', {
          'progress': progress.clamp(0, 100),
          'elapsedSeconds': elapsedSeconds,
        });
      } catch (e) {
        // Ignore if not implemented
      }
    } else if (Platform.isIOS) {
      // Update Live Activity for Dynamic Island
      try {
        // Format elapsed time as HH:MM:SS
        final hours = elapsedSeconds ~/ 3600;
        final minutes = (elapsedSeconds % 3600) ~/ 60;
        final seconds = elapsedSeconds % 60;
        final elapsedTime =
            '${hours.toString().padLeft(2, '0')}:'
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}';

        await _liveActivityChannel.invokeMethod('updateTaskActivity', {
          'elapsedTime': elapsedTime,
          'progress': progress.clamp(0, 100),
          'status': 'Явагдаж буй',
        });
      } catch (e) {
        // Ignore if Live Activities not available
      }
    }
  }

  /// Stop tracking the current task.
  static Future<void> stopTask() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('stop');
      } catch (e) {
        // Ignore if not implemented
      }
    } else if (Platform.isIOS) {
      // End Live Activity for Dynamic Island
      try {
        await _liveActivityChannel.invokeMethod('endTaskActivity');
      } catch (e) {
        // Ignore if Live Activities not available
      }
    }
  }

  /// Check if Live Activities are available (iOS 16.1+)
  static Future<bool> isLiveActivityAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _liveActivityChannel.invokeMethod('isAvailable');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stop live update tracking (alias for stopTask).
  static Future<void> stopLiveUpdate() async {
    return stopTask();
  }
}
