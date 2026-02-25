import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages task photos — saves to local app directory, tracks per task ID.
/// Auto-enhances using the comprehensive 'image' package with progress tracking.
class ImageService {
  static const _prefsKey = 'task_photos';

  /// Get the directory for storing task photos
  static Future<Directory> _photosDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/task_photos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save and auto-enhance a photo for a given task. Returns the saved file path.
  /// Reports progress via [onProgress] (0.0 to 1.0).
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
      onProgress?.call(0.1); // Started
      final sourceBytes = await File(sourcePath).readAsBytes();
      onProgress?.call(0.2); // Read done
      
      // Decode the image (Heaviest part)
      var original = img.decodeImage(sourceBytes);
      onProgress?.call(0.5); // Decode done
      
      if (original == null) {
        await File(sourcePath).copy(destPath);
        onProgress?.call(1.0);
      } else {
        // Apply advanced enhancement pipeline
        final enhanced = _applyPremiumEnhancement(original, onProgress: (p) {
          // Map local progress (0.0-1.0) to global (0.5-0.8)
          onProgress?.call(0.5 + (p * 0.3));
        });
        
        // Encode as JPEG with high quality
        final jpgBytes = img.encodeJpg(enhanced, quality: 90);
        onProgress?.call(0.9); // Encode done
        
        await File(destPath).writeAsBytes(jpgBytes);
        onProgress?.call(1.0); // Save done
      }
    } catch (_) {
      // Fallback: just copy if processing fails
      await File(sourcePath).copy(destPath);
      onProgress?.call(1.0);
    }

    // Update prefs index
    final paths = await getPhotos(taskId);
    paths.add(destPath);
    await _savePaths(taskId, paths);

    return destPath;
  }

  /// Premium enhancement pipeline using the 'image' package
  static img.Image _applyPremiumEnhancement(img.Image src, {void Function(double)? onProgress}) {
    var result = src;

    // 1. Auto Brightness
    result = img.adjustColor(result, brightness: 1.05);
    onProgress?.call(0.2);

    // 2. Contrast boost
    result = img.adjustColor(result, contrast: 1.15);
    onProgress?.call(0.4);

    // 3. Saturation boost
    result = img.adjustColor(result, saturation: 1.10);
    onProgress?.call(0.6);

    // 4. Sharpening
    result = img.convolution(result, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0
    ]);
    onProgress?.call(1.0);

    return result;
  }

  // ═══════════════════════════════════════
  //  CRUD Operations
  // ═══════════════════════════════════════

  /// Get all photo paths for a task
  static Future<List<String>> getPhotos(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString(_prefsKey) ?? '{}';
    final map = json.decode(mapStr) as Map<String, dynamic>;
    final list = map[taskId] as List<dynamic>?;
    if (list == null) return [];
    final paths = <String>[];
    for (final p in list) {
      if (File(p.toString()).existsSync()) {
        paths.add(p.toString());
      }
    }
    return paths;
  }

  /// Delete a specific photo
  static Future<void> deletePhoto(String taskId, String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final paths = await getPhotos(taskId);
    paths.remove(path);
    await _savePaths(taskId, paths);
  }

  /// Get photo count for a task
  static Future<int> getPhotoCount(String taskId) async {
    final photos = await getPhotos(taskId);
    return photos.length;
  }

  /// Save paths list to prefs
  static Future<void> _savePaths(String taskId, List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final mapStr = prefs.getString(_prefsKey) ?? '{}';
    final map = json.decode(mapStr) as Map<String, dynamic>;
    map[taskId] = paths;
    await prefs.setString(_prefsKey, json.encode(map));
  }
}
