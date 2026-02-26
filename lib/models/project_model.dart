/// Project data model — maps to the API's /projects response.
class Project {
  final String id;
  final String ner;
  final String tailbar;
  final String tuluv;        // shine, khiigdej bui, duussan
  final String? ekhlekhOgnoo;
  final String? duusakhOgnoo;
  final String? udirdagchId;
  final List<String> ajiltnuud;
  final String baiguullagiinId;
  final String barilgiinId;
  final DateTime? createdAt;

  Project({
    required this.id,
    required this.ner,
    this.tailbar = '',
    this.tuluv = 'shine',
    this.ekhlekhOgnoo,
    this.duusakhOgnoo,
    this.udirdagchId,
    this.ajiltnuud = const [],
    required this.baiguullagiinId,
    required this.barilgiinId,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    ner: (j['ner'] ?? '').toString(),
    tailbar: (j['tailbar'] ?? '').toString(),
    tuluv: (j['tuluv'] ?? 'shine').toString(),
    ekhlekhOgnoo: j['ekhlekhOgnoo']?.toString(),
    duusakhOgnoo: j['duusakhOgnoo']?.toString(),
    udirdagchId: j['udirdagchId']?.toString(),
    ajiltnuud: List<String>.from(j['ajiltnuud'] ?? []),
    baiguullagiinId: (j['baiguullagiinId'] ?? '').toString(),
    barilgiinId: (j['barilgiinId'] ?? '').toString(),
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'].toString())
        : null,
  );

  /// Status label in Mongolian
  String get tuluvLabel {
    switch (tuluv) {
      case 'shine':         return 'Шинэ';
      case 'khiigdej bui':  return 'Хийгдэж буй';
      case 'duussan':       return 'Дууссан';
      default:              return tuluv;
    }
  }
}
