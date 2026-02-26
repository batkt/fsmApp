import '../models/task_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Minimal service for /tasks endpoints.
class TaskService {
  /// Fetch tasks for a specific project.
  static Future<List<ApiTask>> byProject(String projectId) async {
    final res = await ApiService.get('/tasks', query: {
      'projectId': projectId,
    });
    return _parseList(res);
  }

  /// Fetch tasks assigned to the current user across all projects.
  static Future<List<ApiTask>> myTasks() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    final res = await ApiService.get('/tasks', query: {
      'hariutsagchId': user.id,
    });
    return _parseList(res);
  }

  /// Get a single task by ID.
  static Future<ApiTask?> getById(String id) async {
    final res = await ApiService.get('/tasks/$id');
    if (!res.success) return null;

    final d = res.data is Map && res.data.containsKey('data')
        ? res.data['data']
        : res.data;
    if (d is! Map<String, dynamic>) return null;

    return ApiTask.fromJson(d);
  }

  /// Update a task (e.g. change status).
  static Future<bool> update(String id, Map<String, dynamic> fields) async {
    final res = await ApiService.put('/tasks/$id', body: fields);
    return res.success;
  }

  // ── Internal ──

  static List<ApiTask> _parseList(ApiResult res) {
    if (!res.success) return [];

    final list = res.data is Map
        ? (res.data['data'] ?? res.data['result'] ?? [])
        : res.data;
    if (list is! List) return [];

    return list.map<ApiTask>((j) => ApiTask.fromJson(j)).toList();
  }
}
