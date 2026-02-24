import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/cleaning_task.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/notification_modal.dart';
import '../widgets/summary_row.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_modal.dart';
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
  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _selectedDay = stripTime(DateTime.now());
    _tasks = generateMockTasks();
    _notifications = generateMockNotifications();
  }

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

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

  void _handleStart(CleaningTask t) {
    if (t.status == TaskStatus.completed) return;
    setState(() => t.status = TaskStatus.inProgress);
    _snack('"${t.title}" даалгавар эхэлсэн');
  }

  void _handleFinish(CleaningTask t) {
    if (t.status == TaskStatus.completed) return;
    setState(() => t.status = TaskStatus.completed);
    _snack('"${t.title}" даалгавар дууссан');
  }

  void _handleNextStatus(CleaningTask t) {
    if (t.status == TaskStatus.pending) {
      _handleStart(t);
    } else if (t.status == TaskStatus.inProgress) {
      _handleFinish(t);
    }
  }

  Future<void> _handlePhoto(CleaningTask t) async {
    try {
      final img = await _picker.pickImage(source: ImageSource.camera);
      if (img == null) { _snack('Зураг авагдаагүй'); return; }
      setState(() { t.hasPhoto = true; t.photoCount++; });
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

  void _openNotifications() {
    showNotificationModal(context,
      notifications: _notifications,
      onMarkAllRead: () {
        setState(() {
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true)).toList();
        });
      });
  }

  void _openTaskDetail(CleaningTask t) {
    showTaskDetail(context,
      task: t,
      onStatusChange: () => setState(() => _handleNextStatus(t)),
      onSubtaskToggle: (_) => setState(() {}),
      onPhoto: () => _handlePhoto(t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tasks = _todayTasks;
    final unread = _unreadCount;
    final completedCount = tasks.where(
        (t) => t.status == TaskStatus.completed).length;
    final totalCount = tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Өнөөдрийн цэвэрлэгээ',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // Notification bell
          Stack(children: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: c.muted,
                  borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                onPressed: _openNotifications,
                icon: Icon(Icons.notifications_outlined,
                    color: c.primary),
                tooltip: 'Мэдэгдэл')),
            if (unread > 0) Positioned(right: 6, top: 6,
              child: Container(width: 18, height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: c.background, width: 2)),
                child: Center(child: Text('$unread',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 9, fontWeight: FontWeight.bold))))),
          ]),
          // Profile
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: c.muted,
                borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: _openProfile,
              icon: Icon(Icons.person_outline, color: c.primary),
              tooltip: 'Профайл')),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text('Сайн байна уу, цэвэрлэгч 👋',
                  style: TextStyle(fontSize: 14,
                      color: c.mutedForeground)),
              const SizedBox(height: 4),
              Text('Таны хуваарь',
                  style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.bold, color: c.primary)),
              const SizedBox(height: 16),

              // Calendar
              CalendarStrip(days: _calDays(),
                  selectedDay: _selectedDay,
                  onSelected: (d) =>
                      setState(() => _selectedDay = stripTime(d))),
              const SizedBox(height: 16),

              // Overall progress bar
              if (totalCount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.brandGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: c.brandGreen.withOpacity(0.12))),
                  child: Row(children: [
                    Icon(Icons.pie_chart_rounded, size: 20,
                        color: c.brandGreen),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text('Өнөөдрийн явц',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.primary)),
                        const Spacer(),
                        Text('$completedCount / $totalCount',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: c.brandGreen)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalCount > 0
                              ? completedCount / totalCount : 0,
                          minHeight: 6,
                          backgroundColor: c.muted,
                          valueColor: AlwaysStoppedAnimation(
                              c.brandGreen))),
                    ])),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // Summary chips
              SummaryRow(tasksForDay: tasks),
              const SizedBox(height: 12),

              // Task list
              Expanded(
                child: tasks.isEmpty
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.event_available, size: 48,
                              color: c.border),
                          const SizedBox(height: 8),
                          Text('Энэ өдөр даалгавар байхгүй.',
                              style: TextStyle(
                                  color: c.mutedForeground)),
                        ]))
                    : ListView.separated(
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final t = tasks[i];
                          return TaskCard(
                            task: t,
                            statusColor: _statusColor(t.status, c),
                            statusLabel: _statusLabel(t.status),
                            onStart: () => _handleStart(t),
                            onFinish: () => _handleFinish(t),
                            onAttachPhoto: () => _handlePhoto(t),
                            onTap: () => _openTaskDetail(t),
                          );
                        }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
