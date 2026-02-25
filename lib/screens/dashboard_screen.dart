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
import '../services/widget_service.dart';
import '../services/image_service.dart';
import '../widgets/app_toast.dart';
import 'profile_screen.dart';

class CleanerDashboardScreen extends StatefulWidget {
  const CleanerDashboardScreen({super.key, required this.onLogout});
  final VoidCallback onLogout;
  @override
  State<CleanerDashboardScreen> createState() => _State();
}

class _State extends State<CleanerDashboardScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late DateTime _selectedDay;
  late List<CleaningTask> _tasks;
  late List<AppNotification> _notifications;
  String _filter = 'all'; // 'all', 'pending', 'inProgress', 'completed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDay = stripTime(DateTime.now());
    _tasks = generateMockTasks();
    _notifications = generateMockNotifications();
    _syncWidget();
    _loadSavedPhotos();
  }

  Future<void> _loadSavedPhotos() async {
    for (final t in _tasks) {
      final photos = await ImageService.getPhotos(t.id);
      if (photos.isNotEmpty && mounted) {
        setState(() {
          t.photoPaths.clear();
          t.photoPaths.addAll(photos);
          t.hasPhoto = photos.isNotEmpty;
          t.photoCount = photos.length;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncFromWidget();
    }
  }

  void _syncWidget() {
    WidgetService.updateWidget(_todayTasks);
    WidgetService.updateNotificationWidget(_notifications);
  }

  /// Read state changes from widget (user tapped Start/Finish on widget)
  Future<void> _syncFromWidget() async {
    final changes = await WidgetService.readWidgetChanges(_todayTasks);
    if (changes.isEmpty) return;

    setState(() {
      for (final task in _tasks) {
        if (changes.containsKey(task.id)) {
          task.status = changes[task.id]!;
        }
      }
    });
  }

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  List<CleaningTask> get _allTodayTasks => _tasks
      .where((t) => stripTime(t.date) == stripTime(_selectedDay))
      .toList();


  List<CleaningTask> get _todayTasks {
    var tasks = _tasks
        .where((t) => stripTime(t.date) == stripTime(_selectedDay))
        .toList();

    if (_filter == 'pending') {
      tasks = tasks.where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.overdue).toList();
    } else if (_filter == 'inProgress') {
      tasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    } else if (_filter == 'completed') {
      tasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
    }

    tasks.sort((a, b) {
      final am = a.startTime.hour * 60 + a.startTime.minute;
      final bm = b.startTime.hour * 60 + b.startTime.minute;
      return am.compareTo(bm);
    });
    return tasks;
  }

  Color _statusColor(TaskStatus s, AppColorScheme c) {
    switch (s) {
      case TaskStatus.pending: return c.warningOrange;
      case TaskStatus.inProgress: return c.info;
      case TaskStatus.completed: return c.success;
      case TaskStatus.overdue: return c.destructive;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending: return 'Хүлээгдэж буй';
      case TaskStatus.inProgress: return 'Явагдаж буй';
      case TaskStatus.completed: return 'Дууссан';
      case TaskStatus.overdue: return 'Хугацаа хэтэрсэн';
    }
  }

  void _handleStart(CleaningTask t) {
    if (t.status == TaskStatus.completed) return;
    setState(() => t.status = TaskStatus.inProgress);
    _syncWidget();
    _snack('"${t.title}" даалгавар эхэлсэн');
  }

  void _handleFinish(CleaningTask t) {
    if (t.status == TaskStatus.completed) return;
    setState(() => t.status = TaskStatus.completed);
    _syncWidget();
    _snack('"${t.title}" даалгавар дууссан');
  }

  void _handleNextStatus(CleaningTask t) {
    if (t.status == TaskStatus.pending || t.status == TaskStatus.overdue) {
      _handleStart(t);
    } else if (t.status == TaskStatus.inProgress) {
      _handleFinish(t);
    }
  }

  Future<void> _handlePhoto(CleaningTask t) async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (img == null) return;

      // Update count instantly
      setState(() {
        t.photoPaths.add(img.path);
        t.hasPhoto = true;
        t.photoCount = t.photoPaths.length;
      });

      double progress = 0.0;
      bool isDone = false;

      // Start a timer to fake progress while background isolate works
      // This keeps the UI feeling "alive" and the bar moving.
      void updateProgress(double p) {
        if (!mounted || isDone) return;
        setState(() {
          progress = p;
          AppToast.show(
            context, 
            '📸 Зураг сайжруулж байна...', 
            progress: progress,
            color: context.colors.brandGreen,
          );
        });
      }

      // Initial progress
      updateProgress(0.1);

      // Slow simulate from 10% to 90%
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (isDone || !mounted) return false;
        if (progress < 0.9) {
          updateProgress(progress + 0.05);
          return true;
        }
        return false;
      });

      await ImageService.savePhoto(
        t.id, 
        img.path,
      ).then((savedPath) {
        isDone = true;
        if (mounted) {
          updateProgress(1.0);
          setState(() {
            final idx = t.photoPaths.indexOf(img.path);
            if (idx != -1) t.photoPaths[idx] = savedPath;
          });
          AppToast.show(
            context, 
            '✅ Зураг хадгаллаа',
            icon: Icons.check_circle_rounded,
            color: context.colors.success,
          );
        }
      });
    } catch (_) { 
      AppToast.show(
        context, 
        'Камер нээхэд алдаа гарлаа',
        icon: Icons.error_outline_rounded,
        color: context.colors.destructive,
      );
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    AppToast.show(context, msg);
  }

  void _openProfile() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(
          onLogout: widget.onLogout)));

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
    final allToday = _allTodayTasks;
    final unread = _unreadCount;
    final completedCount = allToday.where(
        (t) => t.status == TaskStatus.completed).length;
    final totalCount = allToday.length;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text('Сайн байна уу, цэвэрлэгч 👋',
                  style: TextStyle(fontSize: 16,
                      color: c.mutedForeground)),
              const SizedBox(height: 4),
              Text('Таны хуваарь',
                  style: TextStyle(fontSize: 24,
                      fontWeight: FontWeight.bold, color: c.primary)),
              const SizedBox(height: 16),

              // Calendar
              FullCalendar(
                  selectedDay: _selectedDay,
                  tasks: _tasks,
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
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.primary)),
                        const Spacer(),
                        Text('$completedCount / $totalCount',
                            style: TextStyle(fontSize: 15,
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
            Row(children: [
              _FilterChip(label: 'Бүгд', value: 'all', selected: _filter, c: c, 
                  onTap: () => setState(() => _filter = 'all')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Хүлээгдэж буй', value: 'pending', selected: _filter, c: c, color: c.warningOrange,
                  onTap: () => setState(() => _filter = 'pending')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Явагдаж буй', value: 'inProgress', selected: _filter, c: c, color: c.info,
                  onTap: () => setState(() => _filter = 'inProgress')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Дууссан', value: 'completed', selected: _filter, c: c, color: c.success,
                  onTap: () => setState(() => _filter = 'completed')),
            ]),
            const SizedBox(height: 12),
            
            // Result count (small)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('${tasks.length} даалгавар',
                  style: TextStyle(fontSize: 13, color: c.mutedForeground)),
            ),

              // Task list (inline, scrolls with page)
              if (tasks.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.event_available, size: 48,
                          color: c.border),
                      const SizedBox(height: 8),
                      Text('Энэ өдөр даалгавар байхгүй.',
                          style: TextStyle(
                              color: c.mutedForeground)),
                    ]),
                ))
              else
                ...tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    task: t,
                    statusColor: _statusColor(t.status, c),
                    statusLabel: _statusLabel(t.status),
                    onStart: () => _handleStart(t),
                    onFinish: () => _handleFinish(t),
                    onAttachPhoto: () => _handlePhoto(t),
                    onTap: () => _openTaskDetail(t),
                  ),
                )),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final AppColorScheme c;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.c,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final activeColor = color ?? c.brandGreen;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : c.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : c.border,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : c.mutedForeground,
          ),
        ),
      ),
    );
  }
}

