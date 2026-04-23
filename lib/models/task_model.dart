/// Baraa (item/material) model
class Baraa {
  final String baraaId;
  final String ner; // Name
  final String negj; // Unit
  final int too; // Quantity
  final double une; // Price
  final double niitUne; // Total price
  final String tailbar; // Description
  final DateTime? ognoo; // Date
  final String? type; // Category type
  final double uldegdel; // Remaining stock

  Baraa({
    required this.baraaId,
    required this.ner,
    required this.negj,
    required this.too,
    required this.une,
    required this.niitUne,
    this.tailbar = '',
    this.ognoo,
    this.type,
    this.uldegdel = 0.0,
  });

  String get negjLabel {
    final n = negj.trim().toLowerCase();
    switch (n) {
      case 'piece':
      case 'shirheg':
      case 'shirxeg':
      case 'sh':
      case 'ш':
      case 'ш.':
      case 'ширхэг':
      case 'ширхэг.':
        return 'Ширхэг';
      case 'box':
      case 'hairtsag':
      case 'хайрцаг':
        return 'Хайрцаг';
      case 'kg':
      case 'kg.':
      case 'кг':
      case 'кг.':
        return 'кг';
      case 'liter':
      case 'litr':
      case 'литр':
        return 'Литр';
      case 'meter':
      case 'metr':
      case 'метр':
        return 'Метр';
      case 'bogts':
      case 'богц':
        return 'Богц';
      case 'dana':
      case 'дан':
        return 'Дан';
      default:
        return negj;
    }
  }

  /// Calculate progress percentage (0.0 to 1.0)
  /// Returns null if cannot calculate
  factory Baraa.fromJson(Map<String, dynamic> j) => Baraa(
    baraaId: (j['baraaId'] ?? j['_id'] ?? '').toString(),
    ner: (j['ner'] ?? '').toString(),
    negj: (j['negj'] ?? '').toString(),
    too: j['too'] is int
        ? j['too']
        : (j['too'] != null ? int.tryParse(j['too'].toString()) ?? 0 : 0),
    une: j['une'] is num
        ? j['une'].toDouble()
        : (j['une'] != null
              ? double.tryParse(j['une'].toString()) ?? 0.0
              : 0.0),
    niitUne: j['niitUne'] is num
        ? j['niitUne'].toDouble()
        : (j['niitUne'] != null
              ? double.tryParse(j['niitUne'].toString()) ?? 0.0
              : 0.0),
    tailbar: (j['tailbar'] ?? j['comment'] ?? j['note'] ?? '').toString(),
    ognoo: TaskZurag._tryParse(j['ognoo']),
    type: j['type']?.toString() ?? j['turul']?.toString(),
    uldegdel: j['uldegdel'] is num 
        ? j['uldegdel'].toDouble() 
        : (j['uldegdel'] != null ? double.tryParse(j['uldegdel'].toString()) ?? 0.0 : 0.0),
  );

  Map<String, dynamic> toJson() => {
    'baraaId': baraaId,
    'ner': ner,
    'negj': negj,
    'too': too,
    'une': une,
    'niitUne': niitUne,
    'tailbar': tailbar,
    if (ognoo != null) 'ognoo': ognoo!.toIso8601String(),
    if (type != null) 'type': type,
    'uldegdel': uldegdel,
  };
}

/// Task image/photo model
class TaskZurag {
  final String? zamNer;
  final String? fileNer;
  final int? khemjee;
  final String? turul;
  final DateTime? ognoo;
  final String? ajiltniiId; // Employee ID who uploaded the image
  final String? ajiltniiNer; // Employee Name who uploaded the image

  TaskZurag({
    this.zamNer,
    this.fileNer,
    this.khemjee,
    this.turul,
    this.ognoo,
    this.ajiltniiId,
    this.ajiltniiNer,
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
    ajiltniiNer: j['ajiltniiNer']?.toString(),
  );

  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Time tracking model for task employees
class AjiltanTsag {
  final String ajiltniiId;
  final DateTime ekhlekhTsag;
  final DateTime? duusakhTsag;
  final int? tsagMinute;
  final String? tailbar;
  final DateTime? ognoo;

  AjiltanTsag({
    required this.ajiltniiId,
    required this.ekhlekhTsag,
    this.duusakhTsag,
    this.tsagMinute,
    this.tailbar,
    this.ognoo,
  });

  factory AjiltanTsag.fromJson(Map<String, dynamic> j) => AjiltanTsag(
    ajiltniiId: (j['ajiltniiId'] ?? '').toString(),
    ekhlekhTsag: TaskZurag._tryParse(j['ekhlekhTsag']) ?? DateTime.now().toUtc(),
    duusakhTsag: TaskZurag._tryParse(j['duusakhTsag']),
    tsagMinute: j['tsagMinute'] is int
        ? j['tsagMinute']
        : (j['tsagMinute'] != null
              ? int.tryParse(j['tsagMinute'].toString())
              : null),
    tailbar: j['tailbar']?.toString(),
    ognoo: TaskZurag._tryParse(j['ognoo']),
  );

  Map<String, dynamic> toJson() => {
    'ajiltniiId': ajiltniiId,
    'ekhlekhTsag': ekhlekhTsag.toIso8601String(),
    if (duusakhTsag != null) 'duusakhTsag': duusakhTsag!.toIso8601String(),
    if (tsagMinute != null) 'tsagMinute': tsagMinute,
    if (tailbar != null) 'tailbar': tailbar,
    if (ognoo != null) 'ognoo': ognoo!.toIso8601String(),
  };
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
  final DateTime? ekhlekhOgnoo;
  final DateTime? duusakhOgnoo;
  final bool isDay;
  final bool isLoop;
  final List<TaskZurag> zurag; // Legacy field (for backward compatibility)
  final List<TaskZurag> hariutsagchZurag; // Images from task creator/assigner
  final List<TaskZurag> ajiltanZurag; // Images from employees
  final List<Baraa> baraa; // Items/materials assigned to the task
  final String baiguullagiinId;
  final String barilgiinId;
  final String? color;
  final List<ApiSubTask> subTasks;
  final List<AjiltanTsag> ajiltanTsag;
  final String? bairshil;
  final String? davkhar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? duussanOgnoo;

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
    this.ekhlekhOgnoo,
    this.duusakhOgnoo,
    this.isDay = false,
    this.isLoop = false,
    this.zurag = const [],
    this.hariutsagchZurag = const [],
    this.ajiltanZurag = const [],
    this.baraa = const [],
    required this.baiguullagiinId,
    required this.barilgiinId,
    this.color,
    this.subTasks = const [],
    this.ajiltanTsag = const [],
    this.bairshil,
    this.davkhar,
    this.createdAt,
    this.updatedAt,
    this.duussanOgnoo,
  });

  factory ApiTask.fromJson(Map<String, dynamic> j) {
    String extractId(dynamic val) {
      if (val is Map) return (val['_id'] ?? val['id'] ?? '').toString();
      return (val ?? '').toString();
    }

    return ApiTask(
      id: extractId(j['_id'] ?? j['id']),
      projectId: extractId(j['projectId']),
      taskId: (j['taskId'] ?? '').toString(),
      ner: (j['ner'] ?? '').toString(),
      bairshil: j['bairshil']?.toString(),
      davkhar: j['davkhar']?.toString(),
      tailbar: (j['tailbar'] ?? '').toString(),
      zereglel: (j['zereglel'] ?? 'engiin').toString(),
      tuluv: (j['tuluv'] ?? 'shine').toString(),
      hariutsagchId: extractId(j['hariutsagchId']),
      ajiltnuud:
          (j['ajiltnuud'] as List?)
              ?.map(extractId)
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
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
      ekhlekhOgnoo: _tryParse(j['ekhlekhOgnoo']),
      duusakhOgnoo: _tryParse(j['duusakhOgnoo']),
      isDay: j['isDay'] == true,
      isLoop: j['isLoop'] == true,
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
      baraa: (j['baraa'] as List<dynamic>? ?? [])
          .map((b) => Baraa.fromJson(b is Map<String, dynamic> ? b : {}))
          .toList(),
      baiguullagiinId: extractId(j['baiguullagiinId']),
      barilgiinId: extractId(j['barilgiinId']),
      color: j['color']?.toString(),
      subTasks: (j['subTasks'] as List<dynamic>? ?? [])
          .map((s) => ApiSubTask.fromJson(s is Map<String, dynamic> ? s : {}))
          .toList(),
      ajiltanTsag: (j['ajiltanTsag'] as List<dynamic>? ?? [])
          .map((a) => AjiltanTsag.fromJson(a is Map<String, dynamic> ? a : {}))
          .toList(),
      createdAt: _tryParse(j['createdAt']),
      updatedAt: _tryParse(j['updatedAt']),
      duussanOgnoo: _tryParse(j['duussanOgnoo']),
    );
  }

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
    final deadline = duusakhOgnoo ?? khugatsaaDuusakhOgnoo;
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline) && tuluv != 'duussan' && tuluv != 'shalga';
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
