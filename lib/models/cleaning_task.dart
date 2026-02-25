import 'package:flutter/material.dart';

enum TaskStatus { pending, inProgress, completed, overdue }
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

  /// Formatted time range string
  String get timeRange {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} - ${fmt(endTime)}';
  }
}

DateTime stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

List<CleaningTask> generateMockTasks() {
  final today = stripTime(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));
  final dayAfter = today.add(const Duration(days: 2));

  return [
    // ── Today's tasks (8 tasks) ──
    CleaningTask(
      id: '1',
      title: 'Үүдний танхим гүнзгий цэвэрлэгээ',
      location: 'Гол үүдний танхим - А цамхаг',
      floor: '1-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 9, minute: 30),
      status: TaskStatus.completed,
      hasPhoto: true,
      photoCount: 2,
      priority: TaskPriority.high,
      estimatedMinutes: 90,
      supervisor: 'Б. Мөнхбат',
      notes: 'Шалны тусгалыг анхаарна уу. Шинэ цэвэрлэгээний бодис хэрэглэнэ.',
      subtasks: [
        SubTask(title: 'Шал шүүрдэх', isDone: true),
        SubTask(title: 'Шал угаах (бодисоор)', isDone: true),
        SubTask(title: 'Тоос арчих', isDone: true),
        SubTask(title: 'Шилнүүд цэвэрлэх', isDone: true),
        SubTask(title: 'Хогийн сав хоослох', isDone: true),
      ],
    ),
    CleaningTask(
      id: '2',
      title: 'Оффисын шал тоос соруулах',
      location: '5-р давхар - Нээлттэй ажлын орчин',
      floor: '5-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 9, minute: 30),
      endTime: const TimeOfDay(hour: 10, minute: 30),
      status: TaskStatus.inProgress,
      priority: TaskPriority.medium,
      estimatedMinutes: 60,
      supervisor: 'Д. Сарантуяа',
      notes: 'Ширээнүүдийн доод хэсгийг анхаарна уу.',
      subtasks: [
        SubTask(title: 'Тоос соруулагч шалгах', isDone: true),
        SubTask(title: 'Бүх өрөөнүүдэд тоос сорох'),
        SubTask(title: 'Хогийн саванд хоосолох'),
      ],
    ),
    CleaningTask(
      id: '3',
      title: 'Ариун цэврийн өрөө цэвэрлэгээ',
      location: '3-р давхар - Баруун жигүүр',
      floor: '3-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 11, minute: 0),
      endTime: const TimeOfDay(hour: 11, minute: 45),
      status: TaskStatus.overdue,
      priority: TaskPriority.high,
      estimatedMinutes: 45,
      supervisor: 'Б. Мөнхбат',
      notes: 'Химийн бодис ашиглах үед бээлий өмсөнө.',
      subtasks: [
        SubTask(title: 'Угаалтуур цэвэрлэх'),
        SubTask(title: 'Суултуур цэвэрлэх'),
        SubTask(title: 'Толь арчих'),
        SubTask(title: 'Шал угаах'),
        SubTask(title: 'Саван/цаас нөхөх'),
        SubTask(title: 'Хогийн сав хоослох'),
      ],
    ),
    CleaningTask(
      id: '4',
      title: 'Хурлын өрөө засаж цэвэрлэх',
      location: '4-р давхар - Хурлын зал А',
      floor: '4-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 12, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 45),
      priority: TaskPriority.medium,
      estimatedMinutes: 45,
      supervisor: 'Д. Сарантуяа',
      notes: 'Хурлын ширээг цэвэрлэж, сандлуудыг эмхлэнэ.',
      subtasks: [
        SubTask(title: 'Ширээ арчих'),
        SubTask(title: 'Сандал эмхлэх'),
        SubTask(title: 'Тоос арчих'),
        SubTask(title: 'Хогийн сав хоослох'),
      ],
    ),
    CleaningTask(
      id: '5',
      title: 'Цайны өрөө цэвэрлэгээ',
      location: '2-р давхар - Амралтын булан',
      floor: '2-р давхар',
      date: today,
      startTime: const TimeOfDay(hour: 13, minute: 0),
      endTime: const TimeOfDay(hour: 13, minute: 30),
      priority: TaskPriority.low,
      estimatedMinutes: 30,
      supervisor: 'Б. Мөнхбат',
      notes: 'Микроволны доторх хэсгийг сайн цэвэрлэнэ.',
      subtasks: [
        SubTask(title: 'Угаалтуур цэвэрлэх'),
        SubTask(title: 'Ширээ арчих'),
        SubTask(title: 'Хөргөгч шалгах'),
        SubTask(title: 'Хогийн сав хоослох'),
      ],
    ),
    CleaningTask(
      id: '6',
      title: 'Шатны хонгил цэвэрлэгээ',
      location: '1-6 давхар шатны хонгил',
      floor: '1-6 давхар',
      date: today,
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 15, minute: 0),
      priority: TaskPriority.medium,
      estimatedMinutes: 60,
      supervisor: 'Д. Сарантуяа',
      notes: 'Гулсах аюулгүй байдлыг анхаарна уу.',
      subtasks: [
        SubTask(title: 'Гар тулгуур арчих'),
        SubTask(title: 'Шат шүүрдэх'),
        SubTask(title: 'Цонх арчих'),
      ],
    ),
    CleaningTask(
      id: '7',
      title: 'Лифтний орчин цэвэрлэх',
      location: 'А цамхаг - Лифтний хонгил',
      floor: 'Бүх давхар',
      date: today,
      startTime: const TimeOfDay(hour: 15, minute: 30),
      endTime: const TimeOfDay(hour: 16, minute: 0),
      priority: TaskPriority.high,
      estimatedMinutes: 30,
      supervisor: 'Б. Мөнхбат',
      notes: 'Лифтний толь, товч, шал бүгдийг цэвэрлэнэ.',
      subtasks: [
        SubTask(title: 'Лифтний доторх толь арчих'),
        SubTask(title: 'Товчлуур арилжих'),
        SubTask(title: 'Шал цэвэрлэх'),
      ],
    ),
    CleaningTask(
      id: '8',
      title: 'Эцсийн шалгалт ба тайлан',
      location: 'Бүх давхар - Нийтлэг',
      floor: 'Бүх давхар',
      date: today,
      startTime: const TimeOfDay(hour: 16, minute: 30),
      endTime: const TimeOfDay(hour: 17, minute: 0),
      priority: TaskPriority.low,
      estimatedMinutes: 30,
      supervisor: 'Б. Мөнхбат',
      notes: 'Өдрийн тайланг бэлтгэж, зургуудыг илгээнэ.',
      subtasks: [
        SubTask(title: 'Бүх өрөө шалгах'),
        SubTask(title: 'Зураг авах'),
        SubTask(title: 'Тайлан бичих'),
      ],
    ),

    // ── Tomorrow ──
    CleaningTask(
      id: '9',
      title: 'Шил & цонх цэвэрлэх',
      location: 'Хүлээн авалт - Гудамжны тал',
      floor: '1-р давхар',
      date: tomorrow,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 11, minute: 0),
      priority: TaskPriority.low,
      estimatedMinutes: 120,
      supervisor: 'Д. Сарантуяа',
      notes: 'Гадна талын цонхнуудыг зөвхөн дотороос нь цэвэрлэнэ.',
      subtasks: [
        SubTask(title: 'Цонх шүршигчээр угаах'),
        SubTask(title: 'Тусгай алчуураар арчих'),
        SubTask(title: 'Цонхны хүрээ цэвэрлэх'),
      ],
    ),
    CleaningTask(
      id: '10',
      title: 'Хүлээн авалтын тасаг',
      location: '1-р давхар - Хүлээн авалт',
      floor: '1-р давхар',
      date: tomorrow,
      startTime: const TimeOfDay(hour: 11, minute: 30),
      endTime: const TimeOfDay(hour: 12, minute: 30),
      priority: TaskPriority.high,
      estimatedMinutes: 60,
      supervisor: 'Б. Мөнхбат',
      subtasks: [
        SubTask(title: 'Ширээ цэвэрлэх'),
        SubTask(title: 'Шал угаах'),
        SubTask(title: 'Цэцэг услах'),
      ],
    ),

    // ── Day After ──
    CleaningTask(
      id: '11',
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
    CleaningTask(
      id: '12',
      title: 'Гаражийн цэвэрлэгээ',
      location: 'Подвал - Машины зогсоол',
      floor: 'Подвал',
      date: dayAfter,
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      priority: TaskPriority.low,
      estimatedMinutes: 120,
      supervisor: 'Д. Сарантуяа',
      subtasks: [
        SubTask(title: 'Шал шүүрдэх'),
        SubTask(title: 'Тоос арчих'),
        SubTask(title: 'Хогийн сав хоослох'),
      ],
    ),
  ];
}
