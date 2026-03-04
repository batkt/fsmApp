import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Service for notification (medegdel) API endpoints.
class NotificationService {
  /// Fetch notifications with optional filters.
  static Future<List<AppNotification>> getNotifications({
    String? ajiltniiId,
    String? baiguullagiinId,
    String? barilgiinId,
    String? projectId,
    String? taskId,
    String? turul,
    bool? kharsanEsekh,
  }) async {
    final query = <String, String>{};
    if (ajiltniiId != null) query['ajiltniiId'] = ajiltniiId;
    if (baiguullagiinId != null) query['baiguullagiinId'] = baiguullagiinId;
    if (barilgiinId != null) query['barilgiinId'] = barilgiinId;
    if (projectId != null) query['projectId'] = projectId;
    if (taskId != null) query['taskId'] = taskId;
    if (turul != null) query['turul'] = turul;
    if (kharsanEsekh != null) query['kharsanEsekh'] = kharsanEsekh.toString();

    final res = await ApiService.get('/medegdel', query: query);
    if (!res.success) return [];

    final list = res.data is Map
        ? (res.data['data'] ?? res.data['result'] ?? [])
        : res.data;
    if (list is! List) return [];

    return list
        .map<AppNotification>((j) => AppNotification.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Get unread notification count.
  static Future<int> getUnreadCount({
    String? ajiltniiId,
    String? baiguullagiinId,
  }) async {
    final query = <String, String>{};
    if (ajiltniiId != null) query['ajiltniiId'] = ajiltniiId;
    if (baiguullagiinId != null) query['baiguullagiinId'] = baiguullagiinId;

    final res = await ApiService.get('/medegdel/unread-count', query: query);
    if (!res.success) return 0;

    if (res.data is Map) {
      return (res.data['count'] ?? 0) as int;
    }
    return 0;
  }

  /// Get a single notification by ID.
  static Future<AppNotification?> getById(String id) async {
    final res = await ApiService.get('/medegdel/$id');
    if (!res.success) return null;

    final d = res.data is Map && res.data.containsKey('data')
        ? res.data['data']
        : res.data;
    if (d is! Map<String, dynamic>) return null;

    return AppNotification.fromJson(d);
  }

  /// Mark a notification as read.
  static Future<bool> markAsRead(String id, {String? ajiltniiId}) async {
    final body = <String, dynamic>{};
    if (ajiltniiId != null) body['ajiltniiId'] = ajiltniiId;

    final res = await ApiService.put('/medegdel/$id/read', body: body.isEmpty ? null : body);
    return res.success;
  }

  /// Mark all notifications as read.
  /// Uses PUT /medegdel/read-all with optional baiguullagiinId query parameter.
  static Future<int> markAllAsRead({
    String? ajiltniiId,
    String? baiguullagiinId,
  }) async {
    // Build query parameters (baiguullagiinId goes in query string)
    final query = <String, String>{};
    if (baiguullagiinId != null) {
      query['baiguullagiinId'] = baiguullagiinId;
    }

    // Body is optional - backend auto-fills ajiltniiId from token
    // Only include ajiltniiId in body if explicitly provided
    final body = <String, dynamic>{};
    if (ajiltniiId != null) {
      body['ajiltniiId'] = ajiltniiId;
    }

    final res = await ApiService.put(
      '/medegdel/read-all',
      query: query.isNotEmpty ? query : null,
      body: body.isNotEmpty ? body : null,
    );
    if (!res.success) return 0;

    if (res.data is Map) {
      return (res.data['count'] ?? 0) as int;
    }
    return 0;
  }

  /// Delete a notification.
  static Future<bool> delete(String id) async {
    final res = await ApiService.delete('/medegdel/$id');
    return res.success;
  }

  /// Get notifications for the current user.
  /// Note: Backend auto-fills ajiltniiId from token, so we don't need to pass it explicitly.
  static Future<List<AppNotification>> myNotifications({
    bool? unreadOnly,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      debugPrint('[NotificationService] No current user');
      return [];
    }

    debugPrint('[NotificationService] Fetching notifications for user: ${user.id}, baiguullaga: ${user.baiguullagaId}');
    
    // Try with explicit filters first
    var notifications = await getNotifications(
      ajiltniiId: user.id,
      baiguullagiinId: user.baiguullagaId,
      kharsanEsekh: unreadOnly == true ? false : null,
    );
    
    // If no results, try letting backend auto-fill from token (don't pass ajiltniiId)
    if (notifications.isEmpty) {
      debugPrint('[NotificationService] No notifications with explicit filters, trying without ajiltniiId (backend auto-fill)');
      notifications = await getNotifications(
        baiguullagiinId: user.baiguullagaId,
        kharsanEsekh: unreadOnly == true ? false : null,
      );
    }
    
    debugPrint('[NotificationService] Fetched ${notifications.length} notifications');
    if (notifications.isNotEmpty) {
      debugPrint('[NotificationService] First notification: ${notifications.first.id}, ajiltniiId: ${notifications.first.ajiltniiId}, turul: ${notifications.first.turul}');
    }
    return notifications;
  }

  /// Get unread count for the current user.
  static Future<int> myUnreadCount() async {
    final user = AuthService.currentUser;
    if (user == null) return 0;

    return getUnreadCount(
      ajiltniiId: user.id,
      baiguullagiinId: user.baiguullagaId,
    );
  }
}
