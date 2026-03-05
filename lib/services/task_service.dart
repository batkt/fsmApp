import '../models/task_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'project_service.dart';

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

    // 1. Get projects where the user is either a manager or a worker
    final projects = await ProjectService.myProjects();
    
    // 2. Fetch all tasks for those projects
    final allTasks = <ApiTask>[];
    for (final p in projects) {
      final pTasks = await byProject(p.id);
      
      // 3. Keep tasks where the user is specifically assigned
      final filteredTasks = pTasks.where((t) => 
        t.hariutsagchId == user.id || t.ajiltnuud.contains(user.id)
      ).toList();
      
      allTasks.addAll(filteredTasks);
    }
    
    return allTasks;
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
