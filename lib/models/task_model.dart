/// Task image/photo model
class TaskZurag {
  final String? zamNer;
  final String? fileNer;
  final int? khemjee;
  final String? turul;
  final DateTime? ognoo;
  final String? ajiltniiId; // Employee ID who uploaded the image

  TaskZurag({
    this.zamNer,
    this.fileNer,
    this.khemjee,
    this.turul,
    this.ognoo,
    this.ajiltniiId,
  });

  factory TaskZurag.fromJson(Map<String, dynamic> j) => TaskZurag(
    zamNer: j['zamNer']?.toString(),
    fileNer: j['fileNer']?.toString(),
    khemjee: j['khemjee'] is int
        ? j['khemjee']
        : (j['khemjee'] != null ? int.tryParse(j['khemjee'].toString()) : null),
    turul: j['turul']?.toString(),
    ognoo: _tryParse(
      j['ognoo'] ?? j['ogno'],
    ), // Support both 'ognoo' and 'ogno'
    ajiltniiId: j['ajiltniiId']?.toString(),
  );

  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Task data model — maps to the API's /tasks response.
class ApiTask {
  final String id;
  final String projectId;
  final String taskId; // e.g. "TES-0001"
  final String ner;
  final String tailbar;
  final String zereglel; // nen yaraltai, yaraltai, engiin, baga
  final String tuluv; // shine, khiigdej bui, shalga, duussan
  final String hariutsagchId;
  final List<String> ajiltnuud;
  final DateTime? ekhlekhTsag;
  final DateTime? duusakhTsag;
  final int? ekhlekhMinute; // Start minute (0-1439, minutes from midnight)
  final int? duusakhMinute; // End minute (0-1439, minutes from midnight)
  final DateTime? khugatsaaDuusakhOgnoo;
  final List<TaskZurag> zurag; // Legacy field (for backward compatibility)
  final List<TaskZurag> hariutsagchZurag; // Images from task creator/assigner
  final List<TaskZurag> ajiltanZurag; // Images from employees
  final String baiguullagiinId;
  final String barilgiinId;
  final String? color;
  final List<ApiSubTask> subTasks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ApiTask({
    required this.id,
    required this.projectId,
    this.taskId = '',
    required this.ner,
    this.tailbar = '',
    this.zereglel = 'engiin',
    this.tuluv = 'shine',
    this.hariutsagchId = '',
    this.ajiltnuud = const [],
    this.ekhlekhTsag,
    this.duusakhTsag,
    this.ekhlekhMinute,
    this.duusakhMinute,
    this.khugatsaaDuusakhOgnoo,
    this.zurag = const [],
    this.hariutsagchZurag = const [],
    this.ajiltanZurag = const [],
    required this.baiguullagiinId,
    required this.barilgiinId,
    this.color,
    this.subTasks = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ApiTask.fromJson(Map<String, dynamic> j) => ApiTask(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    projectId: (j['projectId'] ?? '').toString(),
    taskId: (j['taskId'] ?? '').toString(),
    ner: (j['ner'] ?? '').toString(),
    tailbar: (j['tailbar'] ?? '').toString(),
    zereglel: (j['zereglel'] ?? 'engiin').toString(),
    tuluv: (j['tuluv'] ?? 'shine').toString(),
    hariutsagchId: (j['hariutsagchId'] ?? '').toString(),
    ajiltnuud: List<String>.from(j['ajiltnuud'] ?? []),
    ekhlekhTsag: _tryParse(j['ekhlekhTsag']),
    duusakhTsag: _tryParse(j['duusakhTsag']),
    ekhlekhMinute: j['ekhlekhMinute'] is int
        ? j['ekhlekhMinute']
        : (j['ekhlekhMinute'] != null
              ? int.tryParse(j['ekhlekhMinute'].toString())
              : null),
    duusakhMinute: j['duusakhMinute'] is int
        ? j['duusakhMinute']
        : (j['duusakhMinute'] != null
              ? int.tryParse(j['duusakhMinute'].toString())
              : null),
    khugatsaaDuusakhOgnoo: _tryParse(j['khugatsaaDuusakhOgnoo']),
    // Legacy zurag field (for backward compatibility)
    zurag: (j['zurag'] as List<dynamic>? ?? [])
        .map((z) => TaskZurag.fromJson(z is Map<String, dynamic> ? z : {}))
        .toList(),
    // New separate fields for assigner and employee images
    hariutsagchZurag: (j['hariutsagchZurag'] as List<dynamic>? ?? [])
        .map((z) => TaskZurag.fromJson(z is Map<String, dynamic> ? z : {}))
        .toList(),
    ajiltanZurag: (j['ajiltanZurag'] as List<dynamic>? ?? [])
        .map((z) => TaskZurag.fromJson(z is Map<String, dynamic> ? z : {}))
        .toList(),
    baiguullagiinId: (j['baiguullagiinId'] ?? '').toString(),
    barilgiinId: (j['barilgiinId'] ?? '').toString(),
    color: j['color']?.toString(),
    subTasks: (j['subTasks'] as List<dynamic>? ?? [])
        .map((s) => ApiSubTask.fromJson(s is Map<String, dynamic> ? s : {}))
        .toList(),
    createdAt: _tryParse(j['createdAt']),
    updatedAt: _tryParse(j['updatedAt']),
  );

  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  // ── Display helpers ──

  String get zereglelLabel {
    switch (zereglel) {
      case 'nen yaraltai':
        return 'Нэн яаралтай';
      case 'yaraltai':
        return 'Яаралтай';
      case 'engiin':
        return 'Энгийн';
      case 'baga':
        return 'Бага';
      default:
        return zereglel;
    }
  }

  String get tuluvLabel {
    switch (tuluv) {
      case 'shine':
        return 'Шинэ';
      case 'khiigdej bui':
        return 'Хийгдэж буй';
      case 'shalga':
        return 'Шалгах';
      case 'duussan':
        return 'Дууссан';
      case 'khugatsaa khetersen':
        return 'Хугацаа хэтэрсэн';
      default:
        return tuluv;
    }
  }

  bool get isOverdue {
    if (khugatsaaDuusakhOgnoo == null) return false;
    return DateTime.now().isAfter(khugatsaaDuusakhOgnoo!) && tuluv != 'duussan';
  }
}

class ApiSubTask {
  final String id;
  final String taskId;
  final String projectId;
  final String ner;
  final bool duussan;
  final String baiguullagiinId;
  final String barilgiinId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ApiSubTask({
    required this.id,
    required this.taskId,
    required this.projectId,
    required this.ner,
    this.duussan = false,
    required this.baiguullagiinId,
    required this.barilgiinId,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiSubTask.fromJson(Map<String, dynamic> j) => ApiSubTask(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    taskId: (j['taskId'] ?? '').toString(),
    projectId: (j['projectId'] ?? '').toString(),
    ner: (j['ner'] ?? '').toString(),
    duussan: j['duussan'] == true,
    baiguullagiinId: (j['baiguullagiinId'] ?? '').toString(),
    barilgiinId: (j['barilgiinId'] ?? '').toString(),
    createdAt: _tryParse(j['createdAt']),
    updatedAt: _tryParse(j['updatedAt']),
  );

  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
