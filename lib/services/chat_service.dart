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
    final query = <String, String>{'projectId': projectId};
    if (taskId != null) query['taskId'] = taskId;

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
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final res = await ApiService.post('/chats', body: {
      'projectId': projectId,
      if (taskId != null) 'taskId': taskId,
      'medeelel': medeelel,
      'turul': 'text',
      'barilgiinId': barilgiinId,
      'baiguullagiinId': baiguullagiinId,
      'ajiltniiId': user.id,
      'ajiltniiNer': user.ner,
    });

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
      final file = File(filePath);
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(parts[0], parts[1]),
      ));

      // Fields
      request.fields['projectId'] = projectId;
      if (taskId != null) request.fields['taskId'] = taskId;
      request.fields['barilgiinId'] = barilgiinId;
      request.fields['baiguullagiinId'] = baiguullagiinId;
      request.fields['ajiltniiId'] = user.id;
      request.fields['ajiltniiNer'] = user.ner;
      if (caption != null) request.fields['medeelel'] = caption;

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      final data = json.decode(body);

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        final d = data is Map ? (data['data'] ?? data['result'] ?? data) : data;
        if (d is Map<String, dynamic>) return ChatMessage.fromJson(d);
      }
      return null;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  /// Delete a message.
  static Future<bool> delete(String id) async {
    final res = await ApiService.delete('/chats/$id');
    return res.success;
  }
}
