import 'package:flutter/material.dart';

enum NotifType {
  task,
  alert,
  info,
  success,
  medegdel,
  taskCreated,
  taskUpdated,
  taskCompleted,
  projectCreated,
  projectUpdated,
  chatMessage,
  assignment,
  reminder,
}

class AppNotification {
  final String id;
  final String ajiltniiId;
  final String? khariltsagchiinId;
  final String baiguullagiinId;
  final String barilgiinId;
  final String? khuleenAvagchiinId;
  final String? projectId;
  final String? taskId;
  final String turul;
  final String title;
  final String message;
  final bool kharsanEsekh;
  final String? zurag;
  final Map<String, dynamic>? object;
  final String? adminMedegdelId;
  final int tuluv; // 0 = unread, 1 = read
  final List<String> dakhijKharakhguiAjiltniiIdnuud;
  final bool dakhijKharikhEsekh;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.ajiltniiId,
    this.khariltsagchiinId,
    required this.baiguullagiinId,
    required this.barilgiinId,
    this.khuleenAvagchiinId,
    this.projectId,
    this.taskId,
    this.turul = 'medegdel',
    required this.title,
    required this.message,
    this.kharsanEsekh = false,
    this.zurag,
    this.object,
    this.adminMedegdelId,
    this.tuluv = 0,
    this.dakhijKharakhguiAjiltniiIdnuud = const [],
    this.dakhijKharikhEsekh = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    DateTime? _tryParse(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return AppNotification(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      ajiltniiId: (j['ajiltniiId'] ?? '').toString(),
      khariltsagchiinId: j['khariltsagchiinId']?.toString(),
      baiguullagiinId: (j['baiguullagiinId'] ?? '').toString(),
      barilgiinId: (j['barilgiinId'] ?? '').toString(),
      khuleenAvagchiinId: j['khuleenAvagchiinId']?.toString(),
      projectId: j['projectId']?.toString(),
      taskId: j['taskId']?.toString(),
      turul: (j['turul'] ?? 'medegdel').toString(),
      title: (j['title'] ?? '').toString(),
      message: (j['message'] ?? '').toString(),
      kharsanEsekh: j['kharsanEsekh'] == true || j['tuluv'] == 1,
      zurag: j['zurag']?.toString(),
      object: j['object'] is Map<String, dynamic> ? j['object'] : null,
      adminMedegdelId: j['adminMedegdelId']?.toString(),
      tuluv: j['tuluv'] is int
          ? j['tuluv']
          : (j['tuluv'] != null ? int.tryParse(j['tuluv'].toString()) ?? 0 : 0),
      dakhijKharakhguiAjiltniiIdnuud:
          (j['dakhijKharakhguiAjiltniiIdnuud'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dakhijKharikhEsekh: j['dakhijKharikhEsekh'] == true,
      createdAt: _tryParse(j['createdAt']) ?? DateTime.now(),
      updatedAt: _tryParse(j['updatedAt']) ?? DateTime.now(),
    );
  }

  bool get isRead => kharsanEsekh || tuluv == 1;

  NotifType get type {
    switch (turul) {
      case 'taskCreated':
      case 'taskUpdated':
      case 'taskCompleted':
        return NotifType.task;
      case 'projectCreated':
      case 'projectUpdated':
        return NotifType.info;
      case 'chatMessage':
        return NotifType.info;
      case 'assignment':
        return NotifType.alert;
      case 'reminder':
        return NotifType.alert;
      default:
        return NotifType.medegdel;
    }
  }

  DateTime get time => createdAt;

  String get body => message;

  AppNotification copyWith({bool? isRead}) {
    final read = isRead ?? this.isRead;
    return AppNotification(
      id: id,
      ajiltniiId: ajiltniiId,
      khariltsagchiinId: khariltsagchiinId,
      baiguullagiinId: baiguullagiinId,
      barilgiinId: barilgiinId,
      khuleenAvagchiinId: khuleenAvagchiinId,
      projectId: projectId,
      taskId: taskId,
      turul: turul,
      title: title,
      message: message,
      kharsanEsekh: read,
      zurag: zurag,
      object: object,
      adminMedegdelId: adminMedegdelId,
      tuluv: read ? 1 : 0,
      dakhijKharakhguiAjiltniiIdnuud: dakhijKharakhguiAjiltniiIdnuud,
      dakhijKharikhEsekh: dakhijKharikhEsekh,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

IconData notifIcon(NotifType t) {
  switch (t) {
    case NotifType.task:
    case NotifType.taskCreated:
    case NotifType.taskUpdated:
    case NotifType.taskCompleted:
      return Icons.assignment_rounded;
    case NotifType.alert:
    case NotifType.assignment:
    case NotifType.reminder:
      return Icons.warning_amber_rounded;
    case NotifType.info:
    case NotifType.projectCreated:
    case NotifType.projectUpdated:
    case NotifType.chatMessage:
      return Icons.info_outline_rounded;
    case NotifType.success:
      return Icons.check_circle_outline_rounded;
    case NotifType.medegdel:
      return Icons.notifications_rounded;
  }
}
