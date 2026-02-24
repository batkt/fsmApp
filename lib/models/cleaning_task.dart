import 'package:flutter/material.dart';

enum TaskStatus { pending, inProgress, completed }

class CleaningTask {
  CleaningTask({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = TaskStatus.pending,
    this.hasPhoto = false,
  });

  final String id;
  final String title;
  final String location;
  final DateTime date; // date only (no time component)
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  TaskStatus status;
  bool hasPhoto;
}

DateTime stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

List<CleaningTask> generateMockTasks() {
  final today = stripTime(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));
  final dayAfter = today.add(const Duration(days: 2));

  return [
    CleaningTask(
      id: '1',
      title: 'Үүдний танхим гүнзгий цэвэрлэгээ',
      location: 'Гол үүдний танхим - А цамхаг',
      date: today,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 30),
      status: TaskStatus.inProgress,
      hasPhoto: true,
    ),
    CleaningTask(
      id: '2',
      title: 'Оффисын шал тоос соруулах',
      location: '5-р давхар - Нээлттэй ажлын орчин',
      date: today,
      startTime: const TimeOfDay(hour: 11, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
    ),
    CleaningTask(
      id: '3',
      title: 'Ариун цэврийн өрөө шалгах',
      location: '3-р давхар - Баруун жигүүр',
      date: today,
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 14, minute: 30),
      status: TaskStatus.completed,
      hasPhoto: true,
    ),
    CleaningTask(
      id: '4',
      title: 'Шил & цонх цэвэрлэх',
      location: 'Хүлээн авалт - Гудамжны тал',
      date: tomorrow,
      startTime: const TimeOfDay(hour: 9, minute: 30),
      endTime: const TimeOfDay(hour: 11, minute: 0),
    ),
    CleaningTask(
      id: '5',
      title: 'Агуулах шүүрдэх',
      location: 'Подвал - Хадгалах талбай',
      date: dayAfter,
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 9, minute: 30),
    ),
  ];
}

