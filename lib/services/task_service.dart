import '../models/task_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'project_service.dart';

/// Minimal service for /tasks endpoints.
class TaskService {
  /// Fetch tasks for a specific project.
  static Future<List<ApiTask>> byProject(String projectId) async {
    final user = AuthService.currentUser;
    final res = await ApiService.get('/tasks', query: {
      'projectId': projectId,
      if (user != null) 'ajiltniiId': user.id, // Prefer backend filtering if supported
    });
    
    final all = _parseList(res);
    if (user == null) return all;

    // Optional: If we want managers to see all project tasks, we'd need project info here.
    // For now, to satisfy the privacy request, we filter strictly to assigned tasks
    // unless the user has 'admin' or 'manager' role in their profile.
    final isPrivileged = user.role == 'admin' || user.role == 'manager' || user.role == 'hynalt';
    
    if (isPrivileged) return all;

    // Filter to tasks where user is the responsible person or one of the workers
    return all.where((t) => 
      t.hariutsagchId == user.id || 
      t.ajiltnuud.contains(user.id)
    ).toList();
  }

  /// Fetch tasks assigned to the current user across all projects.
  static Future<List<ApiTask>> myTasks() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    // 1. Get projects where the user is involved
    final projects = await ProjectService.myProjects();
    
    // 2. Fetch all tasks for those projects
    final allTasks = <ApiTask>[];
    for (final p in projects) {
      final pTasks = await byProject(p.id);
      allTasks.addAll(pTasks);
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
