import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';

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
import '../services/shake_detection_service.dart';
import '../services/fcm_service.dart';
import '../services/task_status_service.dart';
import '../services/version_service.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'faq_screen.dart';

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
  bool _faqModalOpen = false;
  Timer? _taskStatusTimer; // Timer for periodic task status updates
  bool _checkedVersionOnce = false;

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
    _initializeFCM();
    _setupSocketListeners();
    _loadNotifications();
    _loadProjects();
    _setupShakeDetection();
    _startTaskStatusChecker();
    _checkForAppUpdate();
  }

  void _setupShakeDetection() {
    debugPrint('[Dashboard] Setting up shake detection');
    ShakeDetectionService.startListening(() {
      debugPrint('[Dashboard] Shake detected callback called');
      // Haptic feedback when help modal will appear
      try {
        HapticFeedback.mediumImpact();
        HapticFeedback.vibrate(); // Fallback for some Android devices
      } catch (_) {
        // Ignore haptic errors
      }
      if (!mounted) {
        debugPrint('[Dashboard] Widget not mounted, skipping navigation');
        return;
      }

      // Try to show modal immediately
      try {
        debugPrint('[Dashboard] Navigating to FAQ screen immediately');
        _showFAQModal();
      } catch (e) {
        // If immediate show fails, schedule for next frame
        debugPrint('[Dashboard] Immediate show failed, scheduling: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint('[Dashboard] Navigating to FAQ screen (scheduled)');
            try {
              _showFAQModal();
            } catch (e2, stackTrace) {
              debugPrint('[Dashboard] ❌ Navigation error: $e2');
              debugPrint('[Dashboard] Stack trace: $stackTrace');
            }
          }
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
  }

  void _showFAQModal() {
    if (!mounted) {
      debugPrint('[Dashboard] Widget not mounted, cannot show FAQ modal');
      return;
    }

    if (_faqModalOpen) {
      debugPrint('[Dashboard] ⚠️ FAQ modal already open, skipping');
      return;
    }

    try {
      _faqModalOpen = true;
      showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            isDismissible: true,
            enableDrag: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: const FAQScreen(),
            ),
          )
          .then((_) {
            _faqModalOpen = false;
            debugPrint('[Dashboard] FAQ modal closed');
          })
          .catchError((error) {
            _faqModalOpen = false;
            debugPrint('[Dashboard] ❌ Error showing FAQ modal: $error');
          });
      debugPrint('[Dashboard] ✅ FAQ screen modal opened');
    } catch (e, stackTrace) {
      _faqModalOpen = false;
      debugPrint('[Dashboard] ❌ Failed to show FAQ modal: $e');
      debugPrint('[Dashboard] Stack trace: $stackTrace');
    }
  }

  Future<void> _initializePushNotifications() async {
    await PushNotificationService.initialize();
    // Set up notification tap handler
    PushNotificationService.onNotificationTapped = _handleNotificationTap;

    // Check permission status
    final hasPermission = await PushNotificationService.isPermissionGranted();
    debugPrint('[Dashboard] Notification permission granted: $hasPermission');
    if (!hasPermission) {
      debugPrint(
        '[Dashboard] ⚠️ Notification permission not granted. User needs to enable it in settings.',
      );
    }
  }

  Future<void> _initializeFCM() async {
    try {
      await FCMService.initialize();
      final token = FCMService.getToken();
      if (token != null) {
        debugPrint('[Dashboard] FCM Token: $token');
        // Register token with backend if user is logged in
        // This works even when user is not logged in - just needs ajiltniiId
        // But we'll register it here after login to ensure it's registered
        await FCMService.registerTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('[Dashboard] FCM initialization error: $e');
      debugPrint(
        '[Dashboard] Continuing without FCM - using local notifications only',
      );
    }
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
    SocketService.onNewNotification((notificationData) async {
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

          // Check if this notification has already been shown as push notification
          final prefs = await SharedPreferences.getInstance();
          final shownIds =
              prefs.getStringList('shown_push_notifications') ?? <String>[];

          if (!shownIds.contains(notification.id)) {
            // Show push notification (works even when app is in background/closed)
            _showPushNotification(notification);

            // Mark as shown
            final updatedShownIds = <String>[...shownIds, notification.id];
            // Keep only last 1000 to prevent storage bloat
            final finalShownIds = updatedShownIds.length > 1000
                ? updatedShownIds.sublist(updatedShownIds.length - 1000)
                : updatedShownIds;
            await prefs.setStringList(
              'shown_push_notifications',
              finalShownIds,
            );
          } else {
            debugPrint(
              '[Dashboard] Notification ${notification.id} already shown as push notification, skipping',
            );
          }
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
    _taskStatusTimer?.cancel();
    ShakeDetectionService.stopListening();
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
      _checkForAppUpdate();
    }
  }

  Future<void> _checkForAppUpdate() async {
    if (!mounted) return;

    // Avoid spamming user: only check once per session
    if (_checkedVersionOnce) return;
    _checkedVersionOnce = true;

    final latest = await VersionService.fetchLatest();
    if (latest == null) return;

    final latestVersion = (latest['latest'] ?? latest['version'])?.toString();
    if (latestVersion == null || latestVersion.isEmpty) return;

    final cmp = VersionService.compareVersions(
      latestVersion,
      VersionService.currentVersion,
    );

    if (cmp <= 0) {
      // We are up-to-date or newer
      return;
    }

    if (!mounted) return;

    // Show update modal
    _showUpdateModal(latestVersion, latest);
  }

  void _showUpdateModal(String latestVersion, Map<String, dynamic> info) {
    final c = context.colors;
    final androidUrl =
        info['androidUrl']?.toString() ?? 'https://play.google.com/';
    final iosUrl = info['iosUrl']?.toString() ?? 'https://apps.apple.com/';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isAndroid = Theme.of(ctx).platform == TargetPlatform.android;
        final storeUrl = isAndroid ? androidUrl : iosUrl;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.system_update_rounded,
                        color: c.brandGreen,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Шинэ хувилбар гарсан байна',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: c.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Хувилбар: $latestVersion',
                              style: TextStyle(
                                fontSize: 14,
                                color: c.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        color: c.mutedForeground,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      info['changelog']?.toString() ??
                          'Шинэ боломжууд болон сайжруулалтууд нэмэгдсэн. Илүү туршлагатай ашиглахын тулд шинэчилнэ үү.',
                      style: TextStyle(
                        fontSize: 14,
                        color: c.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: c.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Дараа',
                            style: TextStyle(
                              fontSize: 14,
                              color: c.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Open store URL via a platform channel (app side must implement)
                            try {
                              const channel = MethodChannel('app_launcher');
                              await channel.invokeMethod('open', {
                                'url': storeUrl,
                              });
                            } catch (e) {
                              debugPrint(
                                '[Dashboard] ❌ Failed to open store URL: $e',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: c.brandGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isAndroid
                                ? 'Play Store руу очих'
                                : 'App Store руу очих',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

      // Get list of notification IDs that have already been shown as push notifications
      final prefs = await SharedPreferences.getInstance();
      final shownIds =
          prefs.getStringList('shown_push_notifications') ?? <String>[];

      // Check for new notifications that weren't in our list before
      final previousIds = _notifications.map((n) => n.id).toSet();
      final newNotifications = notifications
          .where((n) => !previousIds.contains(n.id))
          .toList();

      if (newNotifications.isNotEmpty) {
        debugPrint(
          '[Dashboard] Found ${newNotifications.length} new notifications',
        );

        // Filter out notifications that have already been shown as push notifications
        final notificationsToShow = newNotifications
            .where((n) => !shownIds.contains(n.id))
            .toList();

        // Only show push notifications for the latest 3 unshown notifications
        notificationsToShow.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest3 = notificationsToShow.take(3).toList();

        if (latest3.isNotEmpty) {
          debugPrint(
            '[Dashboard] Showing push notifications for ${latest3.length} latest unshown notifications',
          );

          // Show push notifications and mark them as shown
          final updatedShownIds = <String>[...shownIds];
          for (final notification in latest3) {
            debugPrint(
              '[Dashboard] Showing push notification for notification: ${notification.id}, created: ${notification.createdAt}',
            );
            _showPushNotification(notification);
            updatedShownIds.add(notification.id);
          }

          // Save updated list (keep only last 1000 to prevent storage bloat)
          final finalShownIds = updatedShownIds.length > 1000
              ? updatedShownIds.sublist(updatedShownIds.length - 1000)
              : updatedShownIds;
          await prefs.setStringList('shown_push_notifications', finalShownIds);
        } else {
          debugPrint(
            '[Dashboard] All new notifications have already been shown as push notifications',
          );
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

  /// Show push notification - works even when app is in background or closed
  Future<void> _showPushNotification(AppNotification notification) async {
    try {
      debugPrint(
        '[Dashboard] Showing push notification: ${notification.id}, type: ${notification.turul}',
      );

      // Show push notification for all notification types
      // This will appear on the phone even when app is in background or closed
      if (notification.turul == 'chatMessage') {
        // Check if user is currently viewing this chat
        // If they are, don't show notification (handled in chat screen)
        final isViewingChat = _isViewingChat(
          notification.projectId,
          notification.taskId,
        );

        if (!isViewingChat) {
          await PushNotificationService.showChatNotification(notification);
          debugPrint('[Dashboard] ✅ Chat notification shown');
        } else {
          debugPrint(
            '[Dashboard] ⏭️ Skipping chat notification (user viewing chat)',
          );
        }
      } else {
        // Show all other notification types (task updates, project updates, etc.)
        await PushNotificationService.showNotification(notification);
        debugPrint('[Dashboard] ✅ Notification shown: ${notification.turul}');
      }
    } catch (e, stackTrace) {
      debugPrint('[Dashboard] ❌ Error showing push notification: $e');
      debugPrint('[Dashboard] Stack trace: $stackTrace');
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
  /// Detects status changes and shows appropriate messages
  Future<void> _showTaskUpdatedNotification(ApiTask task) async {
    try {
      String title;
      String message;
      String notificationType;

      // Determine notification type and message based on status
      switch (task.tuluv) {
        case 'khiigdej bui':
          title = 'Даалгавар эхэлсэн';
          message = '${task.ner} (${task.taskId}) даалгавар эхэлсэн цаг ирлээ';
          notificationType = 'taskStarted';
          break;
        case 'duussan':
          title = 'Даалгавар дууссан';
          message = '${task.ner} (${task.taskId}) даалгавар амжилттай дууссан';
          notificationType = 'taskCompleted';
          break;
        case 'khugatsaa khetersen':
          title = 'Хугацаа хэтэрсэн';
          message = '${task.ner} (${task.taskId}) даалгаврын хугацаа хэтэрлээ';
          notificationType = 'taskExpired';
          break;
        case 'shine':
          title = 'Даалгавар шинэчлэгдлээ';
          message =
              '${task.ner} (${task.taskId}) даалгавар дахин шинэ төлөвт шилжлээ';
          notificationType = 'taskReset';
          break;
        default:
          title = 'Даалгавар шинэчлэгдлээ';
          message = '${task.ner} (${task.taskId}) даалгавар шинэчлэгдлээ';
          notificationType = 'taskUpdated';
      }

      await PushNotificationService.showTaskNotification(
        AppNotification(
          id: 'task_${notificationType}_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          ajiltniiId: AuthService.currentUser?.id ?? '',
          baiguullagiinId: task.baiguullagiinId,
          barilgiinId: task.barilgiinId,
          projectId: task.projectId,
          taskId: task.id,
          turul: notificationType,
          title: title,
          message: message,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      debugPrint(
        '[Dashboard] ✅ Task ${notificationType} notification shown for ${task.taskId}',
      );
    } catch (e) {
      debugPrint('[Dashboard] ❌ Error showing task updated notification: $e');
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

    // Filter by selected day
    tasks = tasks
        .where((t) => stripTime(t.date) == stripTime(_selectedDay))
        .toList();

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

    // Optimistically update UI and reset local progress baseline
    setState(() {
      t.startedAtLocal = DateTime.now();
      t.status = TaskStatus.inProgress;
    });
    _syncWidget();
    _snack('"${t.title}" даалгавар эхэлсэн');

    // Update backend status via task-status controller (force khiigdej bui)
    TaskStatusService.updateTaskStatus(t.id, newStatus: 'khiigdej bui').then((
      success,
    ) {
      if (!success && mounted) {
        // Revert on failure
        setState(() => t.status = TaskStatus.pending);
        _syncWidget();
        AppToast.show(
          context,
          'Даалгаврын статус шинэчлэхэд алдаа гарлаа',
          icon: Icons.error_outline_rounded,
          color: context.colors.destructive,
        );
      } else if (success) {
        // Refresh tasks to get updated status and notifications
        if (_selectedProjectId != null) {
          _refreshTasks();
        }
        _loadNotifications();
      }
    });
  }

  void _handleFinish(CleaningTask t) {
    if (t.status == TaskStatus.completed) return;

    // Optimistically update UI
    setState(() => t.status = TaskStatus.completed);
    _syncWidget();
    _snack('"${t.title}" даалгавар дууссан');

    // Update backend status via task-status controller (force duussan)
    TaskStatusService.updateTaskStatus(t.id, newStatus: 'duussan').then((
      success,
    ) {
      if (!success && mounted) {
        // Revert on failure
        setState(() => t.status = TaskStatus.inProgress);
        _syncWidget();
        AppToast.show(
          context,
          'Даалгаврын статус шинэчлэхэд алдаа гарлаа',
          icon: Icons.error_outline_rounded,
          color: context.colors.destructive,
        );
      } else if (success) {
        // Refresh tasks to get updated status and notifications
        if (_selectedProjectId != null) {
          _refreshTasks();
        }
        _loadNotifications();
      }
    });
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
      onStatusChange: () => _handleNextStatus(t),
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Image.asset(
                  'assets/images/zev_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Өнөөдрийн цэвэрлэгээ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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

  /// Start periodic task status checker
  /// Checks and updates task statuses every 5 minutes (configurable via backend)
  void _startTaskStatusChecker() {
    // Check every 5 minutes (300 seconds)
    // Backend scheduler should handle this, but we can also check periodically
    _taskStatusTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      debugPrint('[Dashboard] Periodic task status check...');
      // Update all task statuses via backend
      TaskStatusService.updateAllTasks().then((success) {
        if (success && _selectedProjectId != null) {
          // Refresh tasks after status update
          _refreshTasks();
        }
      });
    });

    debugPrint('[Dashboard] Task status checker started (every 5 minutes)');
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
