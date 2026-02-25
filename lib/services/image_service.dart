import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ProcessingParams {
  final Uint8List bytes;
  final String destPath;
  _ProcessingParams(this.bytes, this.destPath);
}

/// Manages task photos — saves to local app directory, tracks per task ID.
/// Auto-enhances using the 'image' package in a background isolate.
class ImageService {
  static const _prefsKey = 'task_photos';

  static Future<Directory> _photosDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/task_photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Save and auto-enhance a photo. Uses compute() to avoid blocking UI.
  static Future<String> savePhoto(
    String taskId, 
    String sourcePath, {
    void Function(double)? onProgress,
  }) async {
    final dir = await _photosDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${taskId}_$timestamp.jpg';
    final destPath = '${dir.path}/$fileName';

    try {
      onProgress?.call(0.1);
      final sourceBytes = await File(sourcePath).readAsBytes();
      onProgress?.call(0.3);

      // Run heavy processing in background isolate to keep UI responsive
      // Note: compute() doesn't support progress callbacks easily, 
      // but moving the bulk work (decode/encode) off-thread is the priority.
      await compute(_processInBackground, _ProcessingParams(sourceBytes, destPath));
      
      onProgress?.call(1.0);
    } catch (e) {
      debugPrint('Photo processing error: $e');
      await File(sourcePath).copy(destPath);
      onProgress?.call(1.0);
    }

    final paths = await getPhotos(taskId);
    paths.add(destPath);
    await _savePaths(taskId, paths);

    return destPath;
  }

  /// The actual heavy lifting executed in an isolate
  static void _processInBackground(_ProcessingParams params) {
    var original = img.decodeImage(params.bytes);
    if (original == null) {
      File(params.destPath).writeAsBytesSync(params.bytes);
      return;
    }

    // Enhancement pipeline
    var result = img.adjustColor(original, 
      brightness: 1.05, 
      contrast: 1.15, 
      saturation: 1.10
    );

    result = img.convolution(result, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0
    ]);

    final jpgBytes = img.encodeJpg(result, quality: 90);
    File(params.destPath).writeAsBytesSync(jpgBytes);
  }

  static Future<List<String>> getPhotos(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString(_prefsKey) ?? '{}';
    final map = json.decode(mapStr) as Map<String, dynamic>;
    final list = map[taskId] as List<dynamic>?;
    if (list == null) return [];
    final paths = <String>[];
    for (final p in list) {
      if (File(p.toString()).existsSync()) paths.add(p.toString());
    }
    return paths;
  }

  static Future<void> deletePhoto(String taskId, String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    final paths = await getPhotos(taskId);
    paths.remove(path);
    await _savePaths(taskId, paths);
  }

  static Future<int> getPhotoCount(String taskId) async {
    final photos = await getPhotos(taskId);
    return photos.length;
  }

  static Future<void> _savePaths(String taskId, List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString(_prefsKey) ?? '{}';
    final map = json.decode(mapStr) as Map<String, dynamic>;
    map[taskId] = paths;
    await prefs.setString(_prefsKey, json.encode(map));
  }
}
