import 'package:flutter/foundation.dart';
import '../models/project_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'task_service.dart';

/// Minimal service for /projects endpoints.
class ProjectService {
  /// The currently selected project in the dashboard.
  static final ValueNotifier<Project?> activeProject = ValueNotifier(null);
  /// Fetch projects assigned to the current user.
  /// Checks both ajiltnuud (workers) and udirdagchId (manager).
  static Future<List<Project>> myProjects() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    final res = await ApiService.get('/projects', query: {
      'baiguullagiinId': user.baiguullagaId,
    });

    if (!res.success) return [];

    final list = res.data is Map ? (res.data['data'] ?? res.data['result'] ?? []) : res.data;
    if (list is! List) return [];

    final all = list.map<Project>((j) => Project.fromJson(j)).toList();

    // Keep projects where user is a worker, the manager, or assigned to one of
    // its tasks (ажилтныг төслийн даалгаварт л нэмсэн тохиолдол)
    final taskProjectIds = (await TaskService.assignedTasks()).map((t) => t.projectId).toSet();
    return all.where((p) =>
      p.ajiltnuud.contains(user.id) || p.udirdagchId == user.id || taskProjectIds.contains(p.id)
    ).toList();
  }

  /// Fetch all projects for the user's organization.
  static Future<List<Project>> byOrganization() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    final res = await ApiService.get('/projects', query: {
      'baiguullagiinId': user.baiguullagaId,
    });

    if (!res.success) return [];

    final list = res.data is Map ? (res.data['data'] ?? res.data['result'] ?? []) : res.data;
    if (list is! List) return [];

    return list.map<Project>((j) => Project.fromJson(j)).toList();
  }

  /// Get a single project by ID.
  static Future<Project?> getById(String id) async {
    final res = await ApiService.get('/projects/$id');
    if (!res.success) return null;

    final d = res.data is Map && res.data.containsKey('data')
        ? res.data['data']
        : res.data;
    if (d is! Map<String, dynamic>) return null;

    return Project.fromJson(d);
  }
}
