import 'package:flutter/material.dart';

enum NotifType { task, alert, info, success }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final NotifType type;
  final DateTime time;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) =>
      AppNotification(id: id, title: title, body: body,
          type: type, time: time, isRead: isRead ?? this.isRead);
}

IconData notifIcon(NotifType t) {
  switch (t) {
    case NotifType.task: return Icons.assignment_rounded;
    case NotifType.alert: return Icons.warning_amber_rounded;
    case NotifType.info: return Icons.info_outline_rounded;
    case NotifType.success: return Icons.check_circle_outline_rounded;
  }
}

List<AppNotification> generateMockNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: '1',
      title: 'Шинэ даалгавар',
      body: 'Та "Үүдний танхим гүнзгий цэвэрлэгээ" даалгавар хүлээн авлаа.',
      type: NotifType.task,
      time: now.subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: '2',
      title: 'Анхааруулга',
      body: '3-р давхрын ариун цэврийн өрөөний цэвэрлэгээ 30 минутын дараа эхлэнэ.',
      type: NotifType.alert,
      time: now.subtract(const Duration(minutes: 25)),
    ),
    AppNotification(
      id: '3',
      title: 'Зураг батлагдсан',
      body: 'Таны илгээсэн "Оффисын шал" цэвэрлэгээний зураг баталгаажлаа.',
      type: NotifType.success,
      time: now.subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: '4',
      title: 'Хуваарь өөрчлөгдсөн',
      body: 'Маргааш "Шил & цонх цэвэрлэх" даалгаврын цаг 09:30-аас 10:00 болж өөрчлөгдлөө.',
      type: NotifType.info,
      time: now.subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: '5',
      title: 'Сайн ажилласан!',
      body: 'Та өнөөдөр бүх даалгавраа цагтаа гүйцэтгэсэн байна. Баяр хүргэе!',
      type: NotifType.success,
      time: now.subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    AppNotification(
      id: '6',
      title: 'Шинэ мэдэгдэл',
      body: 'Системийн засвар үйлчилгээ 2026-02-25 02:00-04:00 цагт хийгдэнэ.',
      type: NotifType.info,
      time: now.subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];
}
