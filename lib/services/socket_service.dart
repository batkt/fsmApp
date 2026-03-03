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
      // Go online
      final user = AuthService.currentUser;
      if (user != null) {
        _socket!.emit('user_online', {'userId': user.id, 'status': 'online'});
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
    _socket?.emit('join_room', {
      'projectId': projectId,
      if (taskId != null) 'taskId': taskId,
    });
  }

  /// Leave a chat room.
  static void leaveRoom({required String projectId, String? taskId}) {
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

  /// Listen for task created events.
  static void onTaskCreated(void Function(Map<String, dynamic> task) callback) {
    _socket?.on('task_created', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Stop listening for task created events.
  static void offTaskCreated() {
    _socket?.off('task_created');
  }

  /// Listen for task update events.
  static void onTaskUpdated(void Function(Map<String, dynamic> task) callback) {
    _socket?.on('task_updated', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Stop listening for task update events.
  static void offTaskUpdated() {
    _socket?.off('task_updated');
  }

  /// Listen for project created events.
  static void onProjectCreated(
    void Function(Map<String, dynamic> project) callback,
  ) {
    _socket?.on('project_created', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Stop listening for project created events.
  static void offProjectCreated() {
    _socket?.off('project_created');
  }

  /// Listen for project update events.
  static void onProjectUpdated(
    void Function(Map<String, dynamic> project) callback,
  ) {
    _socket?.on('project_updated', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Stop listening for project update events.
  static void offProjectUpdated() {
    _socket?.off('project_updated');
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
