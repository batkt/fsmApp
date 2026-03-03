/// Chat message model — maps to the API's /chats response.
class ChatMessage {
  final String id;
  final String projectId;
  final String? taskId;
  final String ajiltniiId;
  final String ajiltniiNer;
  final String medeelel;
  final String turul;         // text, zurag, file
  final String? fileUrl;
  final String? fileName;
  final String barilgiinId;
  final String baiguullagiinId;
  final DateTime? createdAt;
  final List<String> unshsan;
  final bool isLocal;

  ChatMessage({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.ajiltniiId,
    required this.ajiltniiNer,
    required this.medeelel,
    this.turul = 'text',
    this.fileUrl,
    this.fileName,
    required this.barilgiinId,
    required this.baiguullagiinId,
    this.createdAt,
    this.unshsan = const [],
    this.isLocal = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: (j['_id'] ?? j['id'] ?? '').toString(),
    projectId: (j['projectId'] ?? '').toString(),
    taskId: j['taskId']?.toString(),
    ajiltniiId: (j['ajiltniiId'] ?? '').toString(),
    ajiltniiNer: (j['ajiltniiNer'] ?? '').toString(),
    medeelel: (j['medeelel'] ?? '').toString(),
    turul: (j['turul'] ?? 'text').toString(),
    fileUrl: (j['fileZam'] ?? j['fileUrl'])?.toString(),
    fileName: (j['fileNer'] ?? j['fileName'])?.toString(),
    barilgiinId: (j['barilgiinId'] ?? '').toString(),
    baiguullagiinId: (j['baiguullagiinId'] ?? '').toString(),
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'].toString())?.toUtc()
        : null,
    unshsan: (j['unshsan'] as List?)?.map((e) => e.toString()).toList() ?? [],
    isLocal: false,
  );

  bool get isImage => turul == 'zurag';
  bool get isFile => turul == 'file';
  bool get isText => turul == 'text';

  /// Whether this message was sent by the given user ID.
  bool isMine(String userId) => ajiltniiId == userId;
}
