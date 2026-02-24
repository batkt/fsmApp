import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/cleaning_task.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/summary_row.dart';
import '../widgets/task_card.dart';
import 'profile_screen.dart';

class CleanerDashboardScreen extends StatefulWidget {
  const CleanerDashboardScreen({super.key});
  @override
  State<CleanerDashboardScreen> createState() => _State();
}

class _State extends State<CleanerDashboardScreen> {
  final ImagePicker _picker = ImagePicker();
  late DateTime _selectedDay;
  late List<CleaningTask> _tasks;

  @override
  void initState() {
    super.initState();
    _selectedDay = stripTime(DateTime.now());
    _tasks = generateMockTasks();
  }

  List<DateTime> _calDays() {
    final s = stripTime(DateTime.now()).subtract(const Duration(days: 2));
    return List.generate(7, (i) => s.add(Duration(days: i)));
  }

  List<CleaningTask> get _todayTasks => _tasks
      .where((t) => stripTime(t.date) == stripTime(_selectedDay))
      .toList()
    ..sort((a, b) {
      final am = a.startTime.hour * 60 + a.startTime.minute;
      final bm = b.startTime.hour * 60 + b.startTime.minute;
      return am.compareTo(bm);
    });

  Color _statusColor(TaskStatus s, AppColorScheme c) {
    switch (s) {
      case TaskStatus.pending: return c.warningOrange;
      case TaskStatus.inProgress: return c.info;
      case TaskStatus.completed: return c.success;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending: return 'Хүлээгдэж буй';
      case TaskStatus.inProgress: return 'Явагдаж буй';
      case TaskStatus.completed: return 'Дууссан';
    }
  }

  Future<void> _handleStart(CleaningTask t) async {
    if (t.status == TaskStatus.completed) return;
    setState(() => t.status = TaskStatus.inProgress);
    _snack('"${t.title}" даалгавар эхэлсэн');
  }

  Future<void> _handleFinish(CleaningTask t) async {
    if (t.status == TaskStatus.completed) return;
    setState(() => t.status = TaskStatus.completed);
    _snack('"${t.title}" даалгавар дууссан');
  }

  Future<void> _handlePhoto(CleaningTask t) async {
    try {
      final img = await _picker.pickImage(source: ImageSource.camera);
      if (img == null) { _snack('Зураг авагдаагүй'); return; }
      setState(() => t.hasPhoto = true);
      _snack('Зураг баталгаажуулахаар илгээгдсэн');
    } catch (_) { _snack('Камер нээхэд алдаа гарлаа'); }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)));
  }

  void _openProfile() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tasks = _todayTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Өнөөдрийн цэвэрлэгээ',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: c.muted, borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: _openProfile,
              icon: Icon(Icons.person_outline, color: c.primary),
              tooltip: 'Профайл'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сайн байна уу, цэвэрлэгч,',
                  style: TextStyle(fontSize: 14, color: c.mutedForeground)),
              const SizedBox(height: 4),
              Text('Таны хуваарь',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: c.primary)),
              const SizedBox(height: 16),
              CalendarStrip(days: _calDays(), selectedDay: _selectedDay,
                  onSelected: (d) =>
                      setState(() => _selectedDay = stripTime(d))),
              const SizedBox(height: 16),
              SummaryRow(tasksForDay: tasks),
              const SizedBox(height: 12),
              Expanded(
                child: tasks.isEmpty
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available, size: 48,
                              color: c.border),
                          const SizedBox(height: 8),
                          Text('Энэ өдөр даалгавар байхгүй.',
                              style: TextStyle(color: c.mutedForeground)),
                        ]))
                    : ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final t = tasks[i];
                          return TaskCard(task: t,
                              statusColor: _statusColor(t.status, c),
                              statusLabel: _statusLabel(t.status),
                              onStart: () => _handleStart(t),
                              onFinish: () => _handleFinish(t),
                              onAttachPhoto: () => _handlePhoto(t));
                        }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
