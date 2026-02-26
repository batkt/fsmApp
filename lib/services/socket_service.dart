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

    _socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        .build());

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected');
      _connected = true;
      // Go online
      final user = AuthService.currentUser;
      if (user != null) {
        _socket!.emit('user_online', {
          'userId': user.id,
          'status': 'online',
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

  /// Listen for new messages.
  static void onNewMessage(void Function(ChatMessage msg) callback) {
    _socket?.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        callback(ChatMessage.fromJson(data));
      }
    });
  }

  /// Stop listening for new messages.
  static void offNewMessage() {
    _socket?.off('new_message');
  }

  /// Listen for user status changes.
  static void onUserStatus(void Function(String userId, String status) callback) {
    _socket?.on('user_status_changed', (data) {
      if (data is Map<String, dynamic>) {
        callback(
          (data['userId'] ?? '').toString(),
          (data['status'] ?? 'offline').toString(),
        );
      }
    });
  }

  /// Change own status (online, away, dnd).
  static void changeStatus(String status) {
    _socket?.emit('change_status', {'status': status});
  }
}
