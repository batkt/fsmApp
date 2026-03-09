import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../models/chat_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Minimal service for /chats endpoints + file upload.
class ChatService {
  /// Fetch messages for a project (optionally scoped to a task).
  static Future<List<ChatMessage>> getMessages({
    required String projectId,
    String? taskId,
  }) async {
    final user = AuthService.currentUser;
    final query = <String, String>{
      'projectId': projectId,
      if (user?.baiguullagaId != null) 'baiguullagiinId': user!.baiguullagaId,
    };
    if (taskId != null && taskId.isNotEmpty) query['taskId'] = taskId;

    final res = await ApiService.get('/chats', query: query);
    if (!res.success) return [];

    final list = res.data is Map
        ? (res.data['data'] ?? res.data['result'] ?? [])
        : res.data;
    if (list is! List) return [];

    return list
        .map<ChatMessage>((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Send a text message.
  static Future<ChatMessage?> sendText({
    required String projectId,
    String? taskId,
    required String medeelel,
    required String barilgiinId,
    required String baiguullagiinId,
    ReplyTo? replyTo,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final payload = {
      'projectId': projectId,
      'turul': 'text',
      'barilgiinId': barilgiinId,
      'baiguullagiinId': baiguullagiinId,
      'ajiltniiId': user.id,
      'ajiltniiNer': user.ner,
      if (replyTo != null) 'replyTo': replyTo.toJson(),
    };
    if (taskId != null && taskId.isNotEmpty) payload['taskId'] = taskId;
    if (medeelel.isNotEmpty) payload['medeelel'] = medeelel;

    final res = await ApiService.post('/chats', body: payload);

    if (!res.success) return null;

    final d = res.data is Map
        ? (res.data['data'] ?? res.data['result'] ?? res.data)
        : res.data;

    if (d is! Map<String, dynamic>) return null;
    return ChatMessage.fromJson(d);
  }

  /// Upload a file (image, pdf, etc.) with optional caption.
  static Future<ChatMessage?> uploadFile({
    required String filePath,
    required String projectId,
    String? taskId,
    required String barilgiinId,
    required String baiguullagiinId,
    String? caption,
    ReplyTo? replyTo,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/chats/upload');
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      if (AuthService.token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.token}';
      }

      // File
      final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
      final parts = mimeType.split('/');
      final fileName = filePath.split('/').last;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
        contentType:
            MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream'),
      ));

      // Fields
      request.fields['projectId'] = projectId;
      if (taskId != null && taskId.isNotEmpty)
        request.fields['taskId'] = taskId;
      request.fields['barilgiinId'] = barilgiinId;
      request.fields['baiguullagiinId'] = baiguullagiinId;
      request.fields['ajiltniiId'] = user.id;
      request.fields['ajiltniiNer'] = user.ner;
      if (caption != null && caption.isNotEmpty)
        request.fields['medeelel'] = caption;
      if (replyTo != null) request.fields['replyTo'] = json.encode(replyTo.toJson());

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();
      debugPrint('Upload response: ${streamed.statusCode} | body: $body');

      Map<String, dynamic> data;
      try {
        data = json.decode(body);
      } catch (_) {
        debugPrint('Upload failed to parse JSON');
        return null;
      }

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final d = data['data'] ?? data['result'] ?? data;
        if (d is Map<String, dynamic>) return ChatMessage.fromJson(d);
      }
      return null;
    } catch (e) {
      debugPrint('Upload exception: $e');
      return null;
    }
  }

  /// Edit a message.
  static Future<ChatMessage?> edit(String id, String newText) async {
    final res = await ApiService.patch('/chats/$id', body: {'medeelel': newText});
    if (!res.success) return null;
    
    final d = res.data is Map 
        ? (res.data['data'] ?? res.data['result'] ?? res.data)
        : res.data;

    if (d is! Map<String, dynamic>) return null;
    return ChatMessage.fromJson(d);
  }

  /// Delete a message.
  static Future<bool> delete(String id) async {
    final res = await ApiService.delete('/chats/$id');
    return res.success;
  }

  /// Mark multiple messages as read.
  static Future<void> markAsRead({
    required List<String> chatIds,
    required String projectId,
    String? taskId,
  }) async {
    if (chatIds.isEmpty) return;
    final user = AuthService.currentUser;
    if (user == null) return;

    final payload = {
      'chatIds': chatIds,
      'projectId': projectId,
      'ajiltniiId': user.id,
    };
    if (taskId != null && taskId.isNotEmpty) payload['taskId'] = taskId;

    await ApiService.put('/chats/read', body: payload);
  }
}
