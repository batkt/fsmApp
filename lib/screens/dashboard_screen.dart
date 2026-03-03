import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../models/cleaning_task.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/notification_modal.dart';
import '../widgets/task_detail_modal.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/task_progress_bar.dart';
import '../widgets/task_filter_chips.dart';
import '../widgets/task_list_section.dart';
import '../widgets/project_selector.dart';
import '../models/project_model.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/subtask_service.dart';
import '../services/widget_service.dart';
import '../services/image_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/walkthrough_wrapper.dart';
import '../services/walkthrough_service.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class CleanerDashboardScreen extends StatefulWidget {
  const CleanerDashboardScreen({super.key, required this.onLogout});
  final VoidCallback onLogout;
  @override
  State<CleanerDashboardScreen> createState() => _State();
}

class _State extends State<CleanerDashboardScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late DateTime _selectedDay;
  late List<CleaningTask> _tasks;
  late List<AppNotification> _notifications;
  String _filter = 'all'; // 'all', 'pending', 'inProgress', 'completed'
  String? _selectedProjectId;
  List<Project> _apiProjects = [];
  bool _projectsLoading = true;
  bool _tasksLoading = false;

  // Walkthrough keys
  final GlobalKey _projectSelectorKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _progressBarKey = GlobalKey();
  final GlobalKey _filterChipsKey = GlobalKey();
  final GlobalKey _taskListKey = GlobalKey();
  final GlobalKey _notificationKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDay = stripTime(DateTime.now());
    _tasks = [];
    _notifications = [];

    _initializePushNotifications();
    _setupSocketListeners();
    _loadNotifications();
    _loadProjects();
  }

  Future<void> _initializePushNotifications() async {
    await PushNotificationService.initialize();
    // Set up notification tap handler
    PushNotificationService.onNotificationTapped = _handleNotificationTap;
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || !mounted) return;

    try {
      // Parse JSON payload
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'chatMessage') {
        final projectId = data['projectId'] as String?;
        final taskId = data['taskId'] as String?;
        final barilgiinId = data['barilgiinId'] as String? ?? '';
        final baiguullagiinId = data['baiguullagiinId'] as String? ?? '';

        if (projectId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                projectId: projectId,
                taskId: taskId,
                barilgiinId: barilgiinId,
                baiguullagiinId: baiguullagiinId,
                title: taskId != null ? 'Даалгаврын мессеж' : 'Төслийн мессеж',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Dashboard] Error handling notification tap: $e');
    }
  }

  void _setupSocketListeners() {
    SocketService.connect();

    // Join notification room
    final user = AuthService.currentUser;
    if (user != null) {
      debugPrint('[Dashboard] Joining notification room for user: ${user.id}');
      SocketService.joinNotifications(userId: user.id);
    } else {
      debugPrint('[Dashboard] No current user, cannot join notification room');
    }

    // Listen for new notifications
    SocketService.onNewNotification((notificationData) {
      if (!mounted) return;
      try {
        debugPrint(
          '[Dashboard] Received new notification socket event: $notificationData',
        );
        final notification = AppNotification.fromJson(notificationData);
        debugPrint(
          '[Dashboard] Parsed notification - ID: ${notification.id}, ajiltniiId: ${notification.ajiltniiId}, turul: ${notification.turul}, isRead: ${notification.isRead}',
        );

        // Check if notification is for current user
        final currentUserId = AuthService.currentUser?.id ?? '';
        debugPrint('[Dashboard] Current user ID: $currentUserId');

        if (notification.ajiltniiId == currentUserId) {
          debugPrint(
            '[Dashboard] Notification is for current user, adding to list and showing push notification',
          );
          setState(() {
            // Avoid duplicates
            if (!_notifications.any((n) => n.id == notification.id)) {
              _notifications.insert(0, notification);
              debugPrint(
                '[Dashboard] Added notification to list. Total: ${_notifications.length}',
              );
            } else {
              debugPrint(
                '[Dashboard] Notification already exists in list, skipping duplicate',
              );
            }
          });
          _syncWidget();

          // Show push notification (works even when app is in background/closed)
          // Show even if already marked as read - backend might auto-mark it
          _showPushNotification(notification);
        } else {
          debugPrint(
            '[Dashboard] Notification not for current user. Expected: $currentUserId, Got: ${notification.ajiltniiId}',
          );
        }
      } catch (e, stackTrace) {
        debugPrint('[Dashboard] Error processing notification: $e');
        debugPrint('[Dashboard] Stack trace: $stackTrace');
      }
    });

    // Listen for task created events
    SocketService.onTaskCreated((taskData) {
      if (!mounted) return;
      try {
        debugPrint('[Dashboard] Task created event: $taskData');
        final task = ApiTask.fromJson(taskData);
        final currentUserId = AuthService.currentUser?.id ?? '';

        // Check if user is assigned or is a project member
        final isRelevant =
            task.hariutsagchId == currentUserId ||
            task.ajiltnuud.contains(currentUserId);

        if (isRelevant) {
          // Show push notification
          _showTaskCreatedNotification(task);
        }

        // Refresh tasks if it belongs to current project
        if (task.projectId == _selectedProjectId) {
          _refreshTasks();
        }

        // Refresh notifications to get backend-created notifications
        _loadNotifications();
      } catch (e) {
        debugPrint('[Dashboard] Error handling task_created: $e');
      }
    });

    // Listen for task updated events
    SocketService.onTaskUpdated((taskData) {
      if (!mounted) return;
      try {
        debugPrint('[Dashboard] Task updated event: $taskData');
        final task = ApiTask.fromJson(taskData);
        final currentUserId = AuthService.currentUser?.id ?? '';

        // Check if user is assigned or is a project member
        final isRelevant =
            task.hariutsagchId == currentUserId ||
            task.ajiltnuud.contains(currentUserId);

        if (isRelevant) {
          // Show push notification for important updates
          _showTaskUpdatedNotification(task);
        }

        // Refresh tasks if it belongs to current project
        if (task.projectId == _selectedProjectId) {
          _refreshTasks();
        }

        // Refresh notifications to get backend-created notifications
        _loadNotifications();
      } catch (e) {
        debugPrint('[Dashboard] Error handling task_updated: $e');
      }
    });

    // Listen for project created events
    SocketService.onProjectCreated((projectData) {
      if (!mounted) return;
      try {
        debugPrint('[Dashboard] Project created event: $projectData');
        final projectId = (projectData['_id'] ?? projectData['id'] ?? '')
            .toString();
        final projectNer = (projectData['ner'] ?? '').toString();

        // Show push notification
        _showProjectCreatedNotification(projectId, projectNer);

        // Refresh project list
        _loadProjects();

        // Refresh notifications to get backend-created notifications
        _loadNotifications();
      } catch (e) {
        debugPrint('[Dashboard] Error handling project_created: $e');
      }
    });

    // Listen for project updated events
    SocketService.onProjectUpdated((projectData) {
      if (!mounted) return;
      try {
        debugPrint('[Dashboard] Project updated event: $projectData');
        final projectId = (projectData['_id'] ?? projectData['id'] ?? '')
            .toString();
        final projectNer = (projectData['ner'] ?? '').toString();

        // Show push notification
        _showProjectUpdatedNotification(projectId, projectNer);

        // Refresh project list
        _loadProjects();

        // Refresh notifications to get backend-created notifications
        _loadNotifications();
      } catch (e) {
        debugPrint('[Dashboard] Error handling project_updated: $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up socket listeners
    SocketService.offNewNotification();
    SocketService.offTaskCreated();
    SocketService.offTaskUpdated();
    SocketService.offProjectCreated();
    SocketService.offProjectUpdated();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncFromWidget();
      // Refresh tasks and notifications when app comes to foreground
      if (_selectedProjectId != null) {
        _refreshTasks();
      }
      _loadNotifications();
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

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationService.myNotifications();
      if (!mounted) return;
      debugPrint('[Dashboard] Loaded ${notifications.length} notifications');

      // Check for new notifications that weren't in our list before
      final previousIds = _notifications.map((n) => n.id).toSet();
      final newNotifications = notifications
          .where((n) => !previousIds.contains(n.id))
          .toList();

      if (newNotifications.isNotEmpty) {
        debugPrint(
          '[Dashboard] Found ${newNotifications.length} new notifications',
        );
        // Show push notifications for new notifications (even if marked as read)
        // Backend might auto-mark them as read, but user should still see them
        for (final notification in newNotifications) {
          // Only show if notification is recent (within last 5 minutes)
          final isRecent =
              DateTime.now().difference(notification.createdAt).inMinutes < 5;
          if (isRecent) {
            debugPrint(
              '[Dashboard] Showing push notification for recent notification: ${notification.id}',
            );
            _showPushNotification(notification);
          }
        }
      }

      setState(() {
        _notifications = notifications;
      });
      _syncWidget();
    } catch (e) {
      debugPrint('[Dashboard] Error loading notifications: $e');
    }
  }

  /// Show push notification for chat messages
  /// Only shows if app is in background or closed
  Future<void> _showPushNotification(AppNotification notification) async {
    try {
      // Only show push notification for chat messages
      if (notification.turul == 'chatMessage') {
        // Check if user is currently viewing this chat
        // If they are, don't show notification (handled in chat screen)
        final isViewingChat = _isViewingChat(
          notification.projectId,
          notification.taskId,
        );

        if (!isViewingChat) {
          await PushNotificationService.showChatNotification(notification);
        }
      } else {
        // Show other notifications too
        await PushNotificationService.showNotification(notification);
      }
    } catch (e) {
      debugPrint('[Dashboard] Error showing push notification: $e');
    }
  }

  /// Check if user is currently viewing the chat for this project/task
  bool _isViewingChat(String? projectId, String? taskId) {
    // This is a simple check - in a real app, you'd track the current route
    // For now, we'll assume if the app is in foreground, they might be viewing it
    // The chat screen itself will mark notifications as read when opened
    return false; // Simplified - always show notifications
  }

  /// Show notification for task created
  Future<void> _showTaskCreatedNotification(ApiTask task) async {
    try {
      final title = 'Шинэ даалгавар';
      final message = '${task.ner} (${task.taskId}) даалгавар үүсгэгдлээ';

      await PushNotificationService.showTaskNotification(
        AppNotification(
          id: 'task_created_${task.id}',
          ajiltniiId: AuthService.currentUser?.id ?? '',
          baiguullagiinId: task.baiguullagiinId,
          barilgiinId: task.barilgiinId,
          projectId: task.projectId,
          taskId: task.id,
          turul: 'taskCreated',
          title: title,
          message: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[Dashboard] Error showing task created notification: $e');
    }
  }

  /// Show notification for task updated
  Future<void> _showTaskUpdatedNotification(ApiTask task) async {
    try {
      final title = 'Даалгавар шинэчлэгдлээ';
      final message = '${task.ner} (${task.taskId}) даалгавар шинэчлэгдлээ';

      await PushNotificationService.showTaskNotification(
        AppNotification(
          id: 'task_updated_${task.id}',
          ajiltniiId: AuthService.currentUser?.id ?? '',
          baiguullagiinId: task.baiguullagiinId,
          barilgiinId: task.barilgiinId,
          projectId: task.projectId,
          taskId: task.id,
          turul: 'taskUpdated',
          title: title,
          message: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[Dashboard] Error showing task updated notification: $e');
    }
  }

  /// Show notification for project created
  Future<void> _showProjectCreatedNotification(
    String projectId,
    String projectNer,
  ) async {
    try {
      final title = 'Шинэ төсөл';
      final message = '$projectNer төсөл үүсгэгдлээ';

      await PushNotificationService.showTaskNotification(
        AppNotification(
          id: 'project_created_$projectId',
          ajiltniiId: AuthService.currentUser?.id ?? '',
          baiguullagiinId: '',
          barilgiinId: '',
          projectId: projectId,
          turul: 'projectCreated',
          title: title,
          message: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[Dashboard] Error showing project created notification: $e');
    }
  }

  /// Show notification for project updated
  Future<void> _showProjectUpdatedNotification(
    String projectId,
    String projectNer,
  ) async {
    try {
      final title = 'Төсөл шинэчлэгдлээ';
      final message = '$projectNer төсөл шинэчлэгдлээ';

      await PushNotificationService.showTaskNotification(
        AppNotification(
          id: 'project_updated_$projectId',
          ajiltniiId: AuthService.currentUser?.id ?? '',
          baiguullagiinId: '',
          barilgiinId: '',
          projectId: projectId,
          turul: 'projectUpdated',
          title: title,
          message: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('[Dashboard] Error showing project updated notification: $e');
    }
  }

  List<CleaningTask> get _allTodayTasks => _tasks;

  List<CleaningTask> get _todayTasks {
    var tasks = List<CleaningTask>.from(_tasks);

    if (_filter == 'pending') {
      tasks = tasks
          .where(
            (t) =>
                t.status == TaskStatus.pending ||
                t.status == TaskStatus.overdue,
          )
          .toList();
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
      case TaskStatus.pending:
        return c.warningOrange;
      case TaskStatus.inProgress:
        return c.info;
      case TaskStatus.completed:
        return c.success;
      case TaskStatus.overdue:
        return c.destructive;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return 'Хүлээгдэж буй';
      case TaskStatus.inProgress:
        return 'Явагдаж буй';
      case TaskStatus.completed:
        return 'Дууссан';
      case TaskStatus.overdue:
        return 'Хугацаа хэтэрсэн';
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

      await ImageService.savePhoto(t.id, img.path).then((savedPath) {
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
    MaterialPageRoute(builder: (_) => ProfileScreen(onLogout: widget.onLogout)),
  );

  void _openNotifications() {
    showNotificationModal(
      context,
      notifications: _notifications,
      onMarkAllRead: () async {
        final user = AuthService.currentUser;
        if (user == null) return;

        final count = await NotificationService.markAllAsRead(
          ajiltniiId: user.id,
          baiguullagiinId: user.baiguullagaId,
        );

        debugPrint('[Dashboard] Marked $count notifications as read');

        if (count > 0 && mounted) {
          await _loadNotifications();
        }
      },
      onNotificationTap: (notification) async {
        // Mark as read when tapped
        if (!notification.isRead) {
          await NotificationService.markAsRead(notification.id);
          if (mounted) {
            setState(() {
              final index = _notifications.indexWhere(
                (n) => n.id == notification.id,
              );
              if (index != -1) {
                _notifications[index] = notification.copyWith(isRead: true);
              }
            });
            _syncWidget();
          }
        }

        // Navigate to chat if it's a chat notification
        if (notification.turul == 'chatMessage' &&
            notification.projectId != null) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  projectId: notification.projectId!,
                  taskId: notification.taskId,
                  barilgiinId: notification.barilgiinId,
                  baiguullagiinId: notification.baiguullagiinId,
                  title: notification.taskId != null
                      ? 'Даалгаврын мессеж'
                      : 'Төслийн мессеж',
                ),
              ),
            );
          }
        }
      },
    );
  }

  void _openTaskDetail(CleaningTask t) {
    showTaskDetail(
      context,
      task: t,
      onStatusChange: () => setState(() => _handleNextStatus(t)),
      onSubtaskToggle: (idx) async {
        final sub = t.subtasks[idx];
        final newState = !sub.isDone;

        // Optimistically update UI
        setState(() => sub.isDone = newState);

        // Sync with backend
        final success = await SubTaskService.toggle(sub.id, newState);

        // If API call failed, revert the change
        if (!success && mounted) {
          setState(() => sub.isDone = !newState);
          AppToast.show(
            context,
            'Дэд даалгавар шинэчлэхэд алдаа гарлаа',
            icon: Icons.error_outline_rounded,
            color: context.colors.destructive,
          );
          return;
        }

        // If all subtasks are done, and task is not completed, prompt to finish and go to chat.
        if (t.subtaskProgress >= 1.0 &&
            t.status != TaskStatus.completed &&
            mounted) {
          _handleFinish(t);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                projectId: t.projectId,
                taskId: t.id,
                barilgiinId: t.buildingId,
                baiguullagiinId: AuthService.currentUser?.baiguullagaId ?? '',
                title: '${t.taskCode} Чат',
              ),
            ),
          );
        }
      },
      onPhoto: () => _handlePhoto(t),
    );
  }

  WalkthroughConfig get _walkthroughConfig {
    return WalkthroughConfig(
      screenId: 'dashboard',
      title: 'Хяналтын самбар',
      description: 'Хяналтын самбарын талаар суралцъя',
      steps: [
        WalkthroughStep(
          id: 'project_selector',
          title: 'Төсөл сонгох',
          description:
              'Эндээс өөр төсөл сонгож, төслийн даалгавруудыг харах боломжтой.',
          targetKey: _projectSelectorKey,
          position: WalkthroughPosition.bottom,
        ),
        WalkthroughStep(
          id: 'calendar',
          title: 'Календар',
          description:
              'Календараар өдөр сонгож, тухайн өдрийн даалгавруудыг харах боломжтой.',
          targetKey: _calendarKey,
          position: WalkthroughPosition.bottom,
        ),
        WalkthroughStep(
          id: 'progress',
          title: 'Явцын мэдээлэл',
          description: 'Энд даалгаврын явцын хувь хэмжээг харж болно.',
          targetKey: _progressBarKey,
          position: WalkthroughPosition.bottom,
        ),
        WalkthroughStep(
          id: 'filters',
          title: 'Шүүлт',
          description: 'Даалгавруудыг статусаар нь шүүж харах боломжтой.',
          targetKey: _filterChipsKey,
          position: WalkthroughPosition.bottom,
        ),
        WalkthroughStep(
          id: 'task_list',
          title: 'Даалгаврын жагсаалт',
          description:
              'Энд бүх даалгавруудын жагсаалт байна. Даалгавар дээр дараад дэлгэрэнгүй мэдээлэл харах боломжтой.',
          targetKey: _taskListKey,
          position: WalkthroughPosition.top,
        ),
        WalkthroughStep(
          id: 'notifications',
          title: 'Мэдэгдэл',
          description:
              'Энд бүх мэдэгдлүүд байна. Шинэ мэдэгдэл ирэхэд улаан тоо харагдана.',
          targetKey: _notificationKey,
          position: WalkthroughPosition.bottom,
        ),
        WalkthroughStep(
          id: 'profile',
          title: 'Профайл',
          description:
              'Эндээс профайл мэдээлэл, тохиргоо, гарах зэрэг үйлдлүүдийг хийх боломжтой.',
          targetKey: _profileKey,
          position: WalkthroughPosition.bottom,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tasks = _todayTasks;
    final allToday = _allTodayTasks;
    final unread = _unreadCount;
    final completedCount = allToday
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final totalCount = allToday.length;

    return WalkthroughWrapper(
      config: _walkthroughConfig,
      autoStart: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Өнөөдрийн цэвэрлэгээ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            // Help/Walkthrough button
            Builder(
              builder: (context) => IconButton(
                onPressed: () {
                  context.startWalkthrough();
                },
                icon: Icon(Icons.help_outline, color: c.primary),
                tooltip: 'Тусламж / Заавар',
              ),
            ),
            // Notification bell
            Stack(
              key: _notificationKey,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: c.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _openNotifications,
                    icon: Icon(Icons.notifications_outlined, color: c.primary),
                    tooltip: 'Мэдэгдэл',
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.background, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Profile
            Container(
              key: _profileKey,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _openProfile,
                icon: Icon(Icons.person_outline, color: c.primary),
                tooltip: 'Профайл',
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshTasks,
            color: c.brandGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardHeader(
                    projectSelector: ProjectSelector(
                      key: _projectSelectorKey,
                      isLoading: _projectsLoading,
                      projects: _apiProjects,
                      selectedProjectId: _selectedProjectId,
                      currentProject: _currentProject,
                      onProjectSelected: (projectId) {
                        setState(() => _selectedProjectId = projectId);
                        _loadTasks(projectId);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FullCalendar(
                    key: _calendarKey,
                    selectedDay: _selectedDay,
                    tasks: _tasks,
                    onSelected: (d) =>
                        setState(() => _selectedDay = stripTime(d)),
                  ),
                  const SizedBox(height: 16),
                  if (totalCount > 0) ...[
                    TaskProgressBar(
                      key: _progressBarKey,
                      completedCount: completedCount,
                      totalCount: totalCount,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TaskFilterChips(
                    key: _filterChipsKey,
                    selectedFilter: _filter,
                    onFilterChanged: (filter) =>
                        setState(() => _filter = filter),
                  ),
                  const SizedBox(height: 12),
                  TaskListSection(
                    key: _taskListKey,
                    isLoading: _tasksLoading,
                    tasks: tasks,
                    statusColor: (status) => _statusColor(status, c),
                    statusLabel: _statusLabel,
                    onStart: _handleStart,
                    onFinish: _handleFinish,
                    onAttachPhoto: _handlePhoto,
                    onTap: _openTaskDetail,
                    onChat: (t) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            projectId: t.projectId,
                            taskId: t.id,
                            barilgiinId: t.buildingId,
                            baiguullagiinId:
                                AuthService.currentUser?.baiguullagaId ?? '',
                            title: '${t.taskCode} Чат',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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

    // Fetch subtasks for each task if not already included
    final tasksWithSubtasks = <ApiTask>[];
    for (final apiTask in apiTasks) {
      if (apiTask.subTasks.isNotEmpty) {
        tasksWithSubtasks.add(apiTask);
      } else {
        // Fetch subtasks separately and create new ApiTask with subtasks
        final subtasks = await SubTaskService.byTask(apiTask.id);
        final taskWithSubtasks = ApiTask(
          id: apiTask.id,
          projectId: apiTask.projectId,
          taskId: apiTask.taskId,
          ner: apiTask.ner,
          tailbar: apiTask.tailbar,
          zereglel: apiTask.zereglel,
          tuluv: apiTask.tuluv,
          hariutsagchId: apiTask.hariutsagchId,
          ajiltnuud: apiTask.ajiltnuud,
          ekhlekhTsag: apiTask.ekhlekhTsag,
          duusakhTsag: apiTask.duusakhTsag,
          ekhlekhMinute: apiTask.ekhlekhMinute,
          duusakhMinute: apiTask.duusakhMinute,
          khugatsaaDuusakhOgnoo: apiTask.khugatsaaDuusakhOgnoo,
          zurag: apiTask.zurag,
          baiguullagiinId: apiTask.baiguullagiinId,
          barilgiinId: apiTask.barilgiinId,
          color: apiTask.color,
          subTasks: subtasks,
          createdAt: apiTask.createdAt,
          updatedAt: apiTask.updatedAt,
        );
        tasksWithSubtasks.add(taskWithSubtasks);
      }
    }

    if (!mounted) return;
    setState(() {
      _tasks = tasksWithSubtasks.map((t) => CleaningTask.fromApi(t)).toList();
      _tasksLoading = false;
    });
    _syncWidget();
  }

  /// Refresh tasks for the current project (used by pull-to-refresh and socket events)
  Future<void> _refreshTasks() async {
    if (_selectedProjectId == null) return;
    await _loadTasks(_selectedProjectId!);
  }

  Project? get _currentProject {
    if (_selectedProjectId == null || _apiProjects.isEmpty) return null;
    try {
      final p = _apiProjects.firstWhere((p) => p.id == _selectedProjectId);
      if (ProjectService.activeProject.value?.id != p.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ProjectService.activeProject.value = p;
        });
      }
      return p;
    } catch (_) {
      return null;
    }
  }
}
