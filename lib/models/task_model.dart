/// Task data model — maps to the API's /tasks response.
class ApiTask {
  final String id;
  final String projectId;
  final String taskId;       // e.g. "TES-0001"
  final String ner;
  final String tailbar;
  final String zereglel;     // nen yaraltai, yaraltai, engiin, baga
  final String tuluv;        // shine, khiigdej bui, shalga, duussan
  final String hariutsagchId;
  final List<String> ajiltnuud;
  final DateTime? ekhlekhTsag;
  final DateTime? duusakhTsag;
  final DateTime? khugatsaaDuusakhOgnoo;
  final String baiguullagiinId;
  final String barilgiinId;
  final List<String> zurag;
  final List<ApiSubTask> subTasks;
  final DateTime? createdAt;

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
    this.khugatsaaDuusakhOgnoo,
    required this.baiguullagiinId,
    required this.barilgiinId,
    this.zurag = const [],
    this.subTasks = const [],
    this.createdAt,
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
    khugatsaaDuusakhOgnoo: _tryParse(j['khugatsaaDuusakhOgnoo']),
    baiguullagiinId: (j['baiguullagiinId'] ?? '').toString(),
    barilgiinId: (j['barilgiinId'] ?? '').toString(),
    zurag: List<String>.from(j['zurag'] ?? []),
    subTasks: (j['subTasks'] as List<dynamic>? ?? [])
        .map((s) => ApiSubTask.fromJson(s is Map<String, dynamic> ? s : {}))
        .toList(),
    createdAt: _tryParse(j['createdAt']),
  );

  static DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  // ── Display helpers ──

  String get zereglelLabel {
    switch (zereglel) {
      case 'nen yaraltai': return 'Нэн яаралтай';
      case 'yaraltai':     return 'Яаралтай';
      case 'engiin':       return 'Энгийн';
      case 'baga':         return 'Бага';
      default:             return zereglel;
    }
  }

  String get tuluvLabel {
    switch (tuluv) {
      case 'shine':        return 'Шинэ';
      case 'khiigdej bui': return 'Хийгдэж буй';
      case 'shalga':       return 'Шалгах';
      case 'duussan':      return 'Дууссан';
      default:             return tuluv;
    }
  }

  bool get isOverdue {
    if (khugatsaaDuusakhOgnoo == null) return false;
    return DateTime.now().isAfter(khugatsaaDuusakhOgnoo!) && tuluv != 'duussan';
  }
}

class ApiSubTask {
  final String id;
  final String ner;
  final bool duussan;

  ApiSubTask({required this.id, required this.ner, this.duussan = false});

  factory ApiSubTask.fromJson(Map<String, dynamic> j) => ApiSubTask(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    ner: (j['ner'] ?? '').toString(),
    duussan: j['duussan'] == true,
  );
}
