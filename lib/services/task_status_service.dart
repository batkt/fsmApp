import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../models/task_model.dart';

/// Service for managing task status updates
/// Handles automatic and manual task status changes
class TaskStatusService {
  /// Update all tasks status (triggers backend scheduler)
  static Future<bool> updateAllTasks() async {
    try {
      debugPrint('[TaskStatus] Updating all tasks status...');
      final result = await ApiService.post('/task-status/update-all');

      if (result.success) {
        debugPrint('[TaskStatus] ✅ All tasks updated successfully');
        return true;
      } else {
        debugPrint(
          '[TaskStatus] ❌ Failed to update all tasks: ${result.message}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[TaskStatus] ❌ Error updating all tasks: $e');
      return false;
    }
  }

  /// Update single task status
  /// If [newStatus] is provided, it will be sent as `tuluv` so backend updates immediately.
  /// Otherwise, backend will calculate status based on time rules.
  static Future<bool> updateTaskStatus(
    String taskId, {
    String? newStatus,
    List<Map<String, dynamic>>? ajiltanTsag,
  }) async {
    try {
      debugPrint(
        '[TaskStatus] Updating task status: $taskId, tuluv=$newStatus, hasAjiltanTsag=${ajiltanTsag != null}',
      );

      Map<String, dynamic>? body;
      final user = AuthService.currentUser;
      
      if (user != null && (newStatus != null || ajiltanTsag != null)) {
        body = {
          'ajiltniiId': user.id,
          'baiguullagiinId': user.baiguullagaId,
        };
        if (newStatus != null) body['tuluv'] = newStatus;
        if (ajiltanTsag != null) body['ajiltanTsag'] = ajiltanTsag;
      }

      final result = await ApiService.post(
        '/task-status/update/$taskId',
        body: body,
      );

      if (result.success) {
        debugPrint('[TaskStatus] ✅ Task $taskId updated successfully');
        return true;
      } else {
        debugPrint(
          '[TaskStatus] ❌ Failed to update task $taskId: ${result.message}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[TaskStatus] ❌ Error updating task $taskId: $e');
      return false;
    }
  }

  /// Calculate task status without updating (for preview)
  static Future<String?> calculateTaskStatus(String taskId) async {
    try {
      debugPrint('[TaskStatus] Calculating status for task: $taskId');
      final result = await ApiService.get('/task-status/calculate/$taskId');

      if (result.success) {
        final status = result.data is Map
            ? (result.data['status'] ?? result.data['tuluv'])?.toString()
            : result.data?.toString();
        debugPrint('[TaskStatus] ✅ Calculated status for $taskId: $status');
        return status;
      } else {
        debugPrint(
          '[TaskStatus] ❌ Failed to calculate status: ${result.message}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('[TaskStatus] ❌ Error calculating status: $e');
      return null;
    }
  }

  /// Check scheduler status
  static Future<Map<String, dynamic>?> getSchedulerStatus() async {
    try {
      debugPrint('[TaskStatus] Checking scheduler status...');
      final result = await ApiService.get('/task-status/scheduler');

      if (result.success) {
        debugPrint('[TaskStatus] ✅ Scheduler status retrieved');
        return result.data is Map
            ? Map<String, dynamic>.from(result.data)
            : null;
      } else {
        debugPrint(
          '[TaskStatus] ❌ Failed to get scheduler status: ${result.message}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('[TaskStatus] ❌ Error getting scheduler status: $e');
      return null;
    }
  }

  /// Calculate task status locally based on timestamps
  /// This is a helper method to determine what status a task should have
  static String calculateLocalStatus(ApiTask task) {
    final now = DateTime.now();

    // If manually completed, return duussan
    if (task.tuluv == 'duussan') {
      return 'duussan';
    }

    // Check if expired (khugatsaa khetersen)
    if (task.khugatsaaDuusakhOgnoo != null) {
      if (now.isAfter(task.khugatsaaDuusakhOgnoo!)) {
        return 'khugatsaa khetersen';
      }
    }

    // Check if active (khiigdej bui)
    if (task.ekhlekhTsag != null) {
      if (now.isAfter(task.ekhlekhTsag!) ||
          now.isAtSameMomentAs(task.ekhlekhTsag!)) {
        return 'khiigdej bui';
      }
    }

    // Default to new (shine)
    return 'shine';
  }

  /// Check if task should be updated based on timestamps
  static bool shouldUpdateStatus(ApiTask task) {
    final calculatedStatus = calculateLocalStatus(task);
    return calculatedStatus != task.tuluv;
  }
}
