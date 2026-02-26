import '../models/task_model.dart';
import 'api_service.dart';

/// Minimal service for /subtasks endpoints.
class SubTaskService {
  /// Fetch subtasks for a specific task.
  static Future<List<ApiSubTask>> byTask(String taskId) async {
    final res = await ApiService.get('/subtasks', query: {'taskId': taskId});
    if (!res.success) return [];

    final list = res.data is Map
        ? (res.data['data'] ?? res.data['result'] ?? [])
        : res.data;
    if (list is! List) return [];

    return list
        .map<ApiSubTask>((j) => ApiSubTask.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Create a new subtask.
  static Future<ApiSubTask?> create({
    required String taskId,
    required String projectId,
    required String barilgiinId,
    required String baiguullagiinId,
    required String ner,
  }) async {
    final res = await ApiService.post('/subtasks', body: {
      'taskId': taskId,
      'projectId': projectId,
      'barilgiinId': barilgiinId,
      'baiguullagiinId': baiguullagiinId,
      'ner': ner,
      'duussan': false,
    });
    if (!res.success) return null;

    final d = res.data is Map && res.data.containsKey('data')
        ? res.data['data']
        : res.data;
    if (d is! Map<String, dynamic>) return null;
    return ApiSubTask.fromJson(d);
  }

  /// Toggle subtask done/undone.
  static Future<bool> toggle(String id, bool duussan) async {
    final res = await ApiService.put('/subtasks/$id', body: {
      'duussan': duussan,
    });
    return res.success;
  }

  /// Delete a subtask.
  static Future<bool> delete(String id) async {
    final res = await ApiService.delete('/subtasks/$id');
    return res.success;
  }
}
