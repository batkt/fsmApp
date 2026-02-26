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
import '../models/project_model.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/subtask_service.dart';
import '../services/widget_service.dart';
import '../services/image_service.dart';
import '../widgets/app_toast.dart';
import 'chat_screen.dart';
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
  String? _selectedProjectId;
  List<Project> _apiProjects = [];
  bool _projectsLoading = true;
  bool _tasksLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDay = stripTime(DateTime.now());
    _tasks = [];
    _notifications = generateMockNotifications();
    
    _syncWidget();
    _loadProjects();
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

  List<CleaningTask> get _allTodayTasks => _tasks;


  List<CleaningTask> get _todayTasks {
    var tasks = List<CleaningTask>.from(_tasks);

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
    TaskService.update(t.id, {'tuluv': 'khiigdej bui'});
  }

  void _handleFinish(CleaningTask t) {
    if (t.status == TaskStatus.completed) return;
    setState(() => t.status = TaskStatus.completed);
    _syncWidget();
    _snack('"${t.title}" даалгавар дууссан');
    TaskService.update(t.id, {'tuluv': 'duussan'});
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
      onSubtaskToggle: (idx) async {
        final sub = t.subtasks[idx];
        setState(() => sub.isDone = !sub.isDone);
        await SubTaskService.toggle(sub.id, sub.isDone);

        // If all subtasks are done, and task is not completed, prompt to finish and go to chat.
        if (t.subtaskProgress >= 1.0 && t.status != TaskStatus.completed && mounted) {
           _handleFinish(t);
           Navigator.push(context, MaterialPageRoute(
             builder: (_) => ChatScreen(
                projectId: t.projectId,
                taskId: t.id,
                barilgiinId: t.buildingId,
                baiguullagiinId: AuthService.currentUser?.baiguullagaId ?? '',
                title: '${t.taskCode} - Чат',
             ),
           ));
        }
      },
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
              Text('Сайн байна уу, ${AuthService.currentUser?.ner ?? "цэвэрлэгч"} 👋',
                  style: TextStyle(fontSize: 16,
                      color: c.mutedForeground)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text('Таны хуваарь',
                        style: TextStyle(fontSize: 24,
                            fontWeight: FontWeight.bold, color: c.primary)),
                  ),
                  _buildProjectSelector(c),
                ],
              ),
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
              if (_tasksLoading)
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                      color: c.brandGreen, strokeWidth: 2.5),
                ))
              else if (tasks.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.event_available, size: 48,
                          color: c.border),
                      const SizedBox(height: 8),
                      Text('Даалгавар олдсонгүй.',
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
                    onChat: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                           projectId: t.projectId,
                           taskId: t.id,
                           barilgiinId: t.buildingId,
                           baiguullagiinId: AuthService.currentUser?.baiguullagaId ?? '',
                           title: '${t.taskCode} - Чат',
                        ),
                      ));
                    },
                  ),
                )),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Project API ──

  Future<void> _loadProjects() async {
    final fetched = await ProjectService.myProjects();
    if (!mounted) return;
    setState(() {
      _apiProjects = fetched;
      _projectsLoading = false;
      if (_apiProjects.isNotEmpty) {
        _selectedProjectId = _apiProjects.first.id;
      }
    });
    // Load tasks for the first project
    if (_selectedProjectId != null) {
      _loadTasks(_selectedProjectId!);
    }
  }

  Future<void> _loadTasks(String projectId) async {
    setState(() => _tasksLoading = true);
    final apiTasks = await TaskService.byProject(projectId);
    if (!mounted) return;
    setState(() {
      _tasks = apiTasks.map((t) => CleaningTask.fromApi(t)).toList();
      _tasksLoading = false;
    });
    _syncWidget();
  }

  Project? get _currentProject {
    if (_selectedProjectId == null || _apiProjects.isEmpty) return null;
    try {
      final p = _apiProjects.firstWhere((p) => p.id == _selectedProjectId);
      ProjectService.activeProject.value = p;
      return p;
    } catch (_) {
      return null;
    }
  }

  Widget _buildProjectSelector(AppColorScheme c) {
    if (_projectsLoading) {
      return SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: c.brandGreen),
      );
    }
    if (_apiProjects.isEmpty) {
      return const SizedBox.shrink();
    }

    final name = _currentProject?.ner ?? 'Төсөл';

    return GestureDetector(
      onTap: () => _showProjectModal(c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.brandGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.brandGreen.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_city_rounded, size: 16, color: c.brandGreen),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.brandGreen)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.brandGreen),
          ],
        ),
      ),
    );
  }

  void _showProjectModal(AppColorScheme c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final mc = ctx.colors;
        return Container(
          decoration: BoxDecoration(
            color: mc.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: mc.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: mc.brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.location_city_rounded,
                          color: mc.brandGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Төсөл сонгох',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: mc.primary)),
                          const SizedBox(height: 2),
                          Text('${_apiProjects.length} төсөл олдлоо',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: mc.mutedForeground)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Project list
                  ..._apiProjects.map((project) {
                    final isSelected = project.id == _selectedProjectId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedProjectId = project.id);
                            Navigator.pop(ctx);
                            _loadTasks(project.id);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? mc.brandGreen.withOpacity(0.08)
                                  : mc.muted.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? mc.brandGreen.withOpacity(0.4)
                                    : mc.border.withOpacity(0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? mc.brandGreen.withOpacity(0.15)
                                      : mc.muted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.apartment_rounded,
                                    size: 22,
                                    color: isSelected
                                        ? mc.brandGreen
                                        : mc.mutedForeground),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(project.ner,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? mc.brandGreen
                                                : mc.primary)),
                                    const SizedBox(height: 2),
                                    Text(
                                        isSelected
                                            ? 'Одоо сонгогдсон'
                                            : project.tuluvLabel,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? mc.brandGreen
                                                    .withOpacity(0.7)
                                                : mc.mutedForeground)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: mc.brandGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white),
                                ),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
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

