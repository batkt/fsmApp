import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Socket.IO service for real-time chat and presence.
class SocketService {
  static IO.Socket? _socket;
  static bool _connected = false;

  static bool get isConnected => _connected;

  static String? _currentProjectId;
  static String? _currentTaskId;

  /// Connect to the Socket.IO server.
  static void connect() {
    if (_socket != null) return;

    _socket = IO.io(
      ApiService.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected');
      _connected = true;
      // Go online & join notification room
      final user = AuthService.currentUser;
      if (user != null) {
        _socket!.emit('user_online', {'userId': user.id, 'status': 'online'});
        _socket!.emit('join_notifications', {'userId': user.id});
        
        // Join all building rooms so we receive task_created, task_updated,
        // project_created, project_updated, task_deleted events
        for (final barilgiinId in user.barilguud) {
          if (barilgiinId.isNotEmpty) {
            _socket!.emit('join_barilga', {'barilgiinId': barilgiinId});
            debugPrint('[Socket] Joined barilga room: barilga_$barilgiinId');
          }
        }
      }
      
      // Re-join active chat room if any
      if (_currentProjectId != null) {
        _socket!.emit('join_room', {
          'projectId': _currentProjectId,
          if (_currentTaskId != null) 'taskId': _currentTaskId,
        });
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
      _connected = false;
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connect error: $err');
      _connected = false;
    });
  }

  /// Disconnect from the socket.
  static void disconnect() {
    _socket?.emit('user_online', {
      'userId': AuthService.currentUser?.id ?? '',
      'status': 'offline',
    });
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }

  /// Join a chat room (project or task).
  static void joinRoom({required String projectId, String? taskId}) {
    _currentProjectId = projectId;
    _currentTaskId = taskId;
    _socket?.emit('join_room', {
      'projectId': projectId,
      if (taskId != null) 'taskId': taskId,
    });
  }

  /// Leave a chat room.
  static void leaveRoom({required String projectId, String? taskId}) {
    if (_currentProjectId == projectId && _currentTaskId == taskId) {
      _currentProjectId = null;
      _currentTaskId = null;
    }
    _socket?.emit('leave_room', {
      'projectId': projectId,
      if (taskId != null) 'taskId': taskId,
    });
  }


  static final Map<String, String> _onlineUsers = {};

  static Map<String, String> get onlineUsers => _onlineUsers;

  static void onNewMessage(void Function(ChatMessage msg) callback) {
    _socket?.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        callback(ChatMessage.fromJson(data));
      }
    });
  }

  static void offNewMessage() {
    _socket?.off('new_message');
  }

  static void onMessageEdited(void Function(ChatMessage msg) callback) {
    _socket?.on('message_edited', (data) {
      if (data is Map<String, dynamic>) {
        callback(ChatMessage.fromJson(data));
      }
    });
  }

  static void offMessageEdited() {
    _socket?.off('message_edited');
  }

  static void onMessageDeleted(void Function(String chatId) callback) {
    _socket?.on('message_deleted', (data) {
      if (data is Map<String, dynamic>) {
        callback((data['chatId'] ?? '').toString());
      }
    });
  }

  static void offMessageDeleted() {
    _socket?.off('message_deleted');
  }

  static void onUserStatus(
    void Function(String userId, String status)? callback,
  ) {
    if (_socket == null) return;

    _socket!.on('online_users', (data) {
      if (data is List) {
        _onlineUsers.clear();
        for (var item in data) {
          if (item is List && item.length == 2) {
            _onlineUsers[item[0].toString()] = item[1].toString();
          }
        }
        if (callback != null) callback('sync', 'sync');
      }
    });

    _socket!.on('user_status_changed', (data) {
      if (data is Map<String, dynamic>) {
        final uid = (data['userId'] ?? '').toString();
        final sts = (data['status'] ?? 'offline').toString();
        _onlineUsers[uid] = sts;
        if (callback != null) callback(uid, sts);
      }
    });
  }

  static void offUserStatus() {
    _socket?.off('online_users');
    _socket?.off('user_status_changed');
  }

  /// Listen for messages being marked as read.
  static void onMessagesRead(
    void Function(List<String> chatIds, String userId) callback,
  ) {
    _socket?.on('messages_read', (data) {
      if (data is Map<String, dynamic>) {
        final ids =
            (data['chatIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final uid = (data['ajiltniiId'] ?? '').toString();
        callback(ids, uid);
      }
    });
  }

  /// Stop listening for read receipts.
  static void offMessagesRead() {
    _socket?.off('messages_read');
  }

  static void changeStatus(String status) {
    _socket?.emit('change_status', {'status': status});
  }

  static final List<void Function(Map<String, dynamic>)> _taskCreatedListeners = [];
  static final List<void Function(Map<String, dynamic>)> _taskUpdatedListeners = [];
  static final List<void Function(Map<String, dynamic>)> _taskDeletedListeners = [];
  static final List<void Function(Map<String, dynamic>)> _projectCreatedListeners = [];
  static final List<void Function(Map<String, dynamic>)> _projectUpdatedListeners = [];
  static final List<void Function(Map<String, dynamic>)> _kpiUpdatedListeners = [];
  
  /// Listen for task created events.
  static void onTaskCreated(void Function(Map<String, dynamic> task) callback) {
    if (_taskCreatedListeners.isEmpty) {
      _socket?.on('task_created', (data) {
        if (data is Map<String, dynamic>) {
          for (var cb in _taskCreatedListeners.toList()) cb(data);
        }
      });
    }
    _taskCreatedListeners.add(callback);
  }

  /// Stop listening for task created events.
  static void offTaskCreated([void Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _taskCreatedListeners.remove(callback);
    } else {
      _taskCreatedListeners.clear();
    }
    if (_taskCreatedListeners.isEmpty) _socket?.off('task_created');
  }

  /// Listen for task update events.
  static void onTaskUpdated(void Function(Map<String, dynamic> task) callback) {
    if (_taskUpdatedListeners.isEmpty) {
      _socket?.on('task_updated', (data) {
        if (data is Map<String, dynamic>) {
          for (var cb in _taskUpdatedListeners.toList()) cb(data);
        }
      });
    }
    _taskUpdatedListeners.add(callback);
  }

  /// Stop listening for task update events.
  static void offTaskUpdated([void Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _taskUpdatedListeners.remove(callback);
    } else {
      _taskUpdatedListeners.clear();
    }
    if (_taskUpdatedListeners.isEmpty) _socket?.off('task_updated');
  }

  /// Listen for task deleted events.
  static void onTaskDeleted(void Function(Map<String, dynamic> data) callback) {
    if (_taskDeletedListeners.isEmpty) {
      _socket?.on('task_deleted', (data) {
        if (data is Map<String, dynamic>) {
          for (var cb in _taskDeletedListeners.toList()) cb(data);
        }
      });
    }
    _taskDeletedListeners.add(callback);
  }

  /// Stop listening for task deleted events.
  static void offTaskDeleted([void Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _taskDeletedListeners.remove(callback);
    } else {
      _taskDeletedListeners.clear();
    }
    if (_taskDeletedListeners.isEmpty) _socket?.off('task_deleted');
  }

  /// Listen for KPI update events.
  static void onKpiUpdated(void Function(Map<String, dynamic> kpi) callback) {
    if (_kpiUpdatedListeners.isEmpty) {
      _socket?.on('kpi_updated', (data) {
        if (data is Map<String, dynamic>) {
          for (var cb in _kpiUpdatedListeners.toList()) cb(data);
        }
      });
    }
    _kpiUpdatedListeners.add(callback);
  }

  /// Stop listening for KPI update events.
  static void offKpiUpdated([void Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _kpiUpdatedListeners.remove(callback);
    } else {
      _kpiUpdatedListeners.clear();
    }
    if (_kpiUpdatedListeners.isEmpty) _socket?.off('kpi_updated');
  }


  /// Listen for project created events.
  static void onProjectCreated(
    void Function(Map<String, dynamic> project) callback,
  ) {
    if (_projectCreatedListeners.isEmpty) {
      _socket?.on('project_created', (data) {
        if (data is Map<String, dynamic>) {
          for (var cb in _projectCreatedListeners.toList()) cb(data);
        }
      });
    }
    _projectCreatedListeners.add(callback);
  }

  /// Stop listening for project created events.
  static void offProjectCreated([void Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _projectCreatedListeners.remove(callback);
    } else {
      _projectCreatedListeners.clear();
    }
    if (_projectCreatedListeners.isEmpty) _socket?.off('project_created');
  }

  /// Listen for project update events.
  static void onProjectUpdated(
    void Function(Map<String, dynamic> project) callback,
  ) {
    if (_projectUpdatedListeners.isEmpty) {
      _socket?.on('project_updated', (data) {
        if (data is Map<String, dynamic>) {
          for (var cb in _projectUpdatedListeners.toList()) cb(data);
        }
      });
    }
    _projectUpdatedListeners.add(callback);
  }

  /// Stop listening for project update events.
  static void offProjectUpdated([void Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _projectUpdatedListeners.remove(callback);
    } else {
      _projectUpdatedListeners.clear();
    }
    if (_projectUpdatedListeners.isEmpty) _socket?.off('project_updated');
  }

  /// Join notification room for a user.
  static void joinNotifications({required String userId}) {
    _socket?.emit('join_notifications', {'userId': userId});
  }

  /// Leave notification room.
  static void leaveNotifications() {
    _socket?.off('join_notifications');
  }

  /// Listen for new notification events.
  static void onNewNotification(
    void Function(Map<String, dynamic> notification) callback,
  ) {
    _socket?.on('new_notification', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Stop listening for new notification events.
  static void offNewNotification() {
    _socket?.off('new_notification');
  }
}
