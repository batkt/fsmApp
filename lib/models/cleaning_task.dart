import 'package:flutter/material.dart';

enum TaskStatus { pending, inProgress, completed }
enum TaskPriority { high, medium, low }

class SubTask {
  SubTask({required this.title, this.isDone = false});
  final String title;
  bool isDone;
}

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
    this.priority = TaskPriority.medium,
    this.floor = '',
    this.notes = '',
    this.supervisor = '',
    this.estimatedMinutes = 0,
    this.subtasks = const [],
    this.photoCount = 0,
  });

  final String id;
  final String title;
  final String location;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TaskPriority priority;
  final String floor;
  final String notes;
  final String supervisor;
  final int estimatedMinutes;
  final List<SubTask> subtasks;
  TaskStatus status;
  bool hasPhoto;
  int photoCount;

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    return subtasks.where((s) => s.isDone).length / subtasks.length;
  }

  int get subtasksDone => subtasks.where((s) => s.isDone).length;
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
      floor: '1-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 30),
      status: TaskStatus.inProgress,
      hasPhoto: true,
      photoCount: 2,
      priority: TaskPriority.high,
      estimatedMinutes: 90,
      supervisor: 'Б. Мөнхбат',
      notes: 'Шалны тусгалыг анхаарна уу. Шинэ цэвэрлэгээний бодис хэрэглэнэ.',
      subtasks: [
        SubTask(title: 'Шал шүүрдэх', isDone: true),
        SubTask(title: 'Шал угаах (бодисоор)', isDone: true),
        SubTask(title: 'Тоос арчих', isDone: false),
        SubTask(title: 'Шилнүүд цэвэрлэх', isDone: false),
        SubTask(title: 'Хогийн сав хоослох', isDone: true),
      ],
    ),
    CleaningTask(
      id: '2',
      title: 'Оффисын шал тоос соруулах',
      location: '5-р давхар - Нээлттэй ажлын орчин',
      floor: '5-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 11, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      priority: TaskPriority.medium,
      estimatedMinutes: 60,
      supervisor: 'Д. Сарантуяа',
      notes: 'Ширээнүүдийн доод хэсгийг анхаарна уу.',
      subtasks: [
        SubTask(title: 'Тоос соруулагч шалгах'),
        SubTask(title: 'Бүх өрөөнүүдэд тоос сорох'),
        SubTask(title: 'Хогийн саванд хоосолох'),
      ],
    ),
    CleaningTask(
      id: '3',
      title: 'Ариун цэврийн өрөө шалгах',
      location: '3-р давхар - Баруун жигүүр',
      floor: '3-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 14, minute: 30),
      status: TaskStatus.completed,
      hasPhoto: true,
      photoCount: 3,
      priority: TaskPriority.high,
      estimatedMinutes: 30,
      supervisor: 'Б. Мөнхбат',
      notes: '',
      subtasks: [
        SubTask(title: 'Угаалтуур цэвэрлэх', isDone: true),
        SubTask(title: 'Суултуур цэвэрлэх', isDone: true),
        SubTask(title: 'Толь арчих', isDone: true),
        SubTask(title: 'Шал угаах', isDone: true),
        SubTask(title: 'Саван/цаас нөхөх', isDone: true),
        SubTask(title: 'Хогийн сав хоослох', isDone: true),
      ],
    ),
    CleaningTask(
      id: '4',
      title: 'Шил & цонх цэвэрлэх',
      location: 'Хүлээн авалт - Гудамжны тал',
      floor: '1-р давхар',
      date: tomorrow,
      startTime: const TimeOfDay(hour: 9, minute: 30),
      endTime: const TimeOfDay(hour: 11, minute: 0),
      priority: TaskPriority.low,
      estimatedMinutes: 90,
      supervisor: 'Д. Сарантуяа',
      notes: 'Гадна талын цонхнуудыг зөвхөн дотороос нь цэвэрлэнэ.',
      subtasks: [
        SubTask(title: 'Цонх шүршигчээр угаах'),
        SubTask(title: 'Тусгай алчуураар арчих'),
        SubTask(title: 'Цонхны хүрээ цэвэрлэх'),
      ],
    ),
    CleaningTask(
      id: '5',
      title: 'Агуулах шүүрдэх',
      location: 'Подвал - Хадгалах талбай',
      floor: 'Подвал',
      date: dayAfter,
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 9, minute: 30),
      priority: TaskPriority.medium,
      estimatedMinutes: 90,
      supervisor: 'Б. Мөнхбат',
      notes: 'Хүнд зүйлсийг зөөхгүй. Зөвхөн шал цэвэрлэнэ.',
      subtasks: [
        SubTask(title: 'Хог хаягдал цэвэрлэх'),
        SubTask(title: 'Шал шүүрдэх'),
        SubTask(title: 'Бохир толбо арилгах'),
        SubTask(title: 'Зураг авах'),
      ],
    ),
  ];
}
