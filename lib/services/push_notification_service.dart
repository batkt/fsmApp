import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

/// Service for showing push notifications (local notifications)
class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String?)? onNotificationTapped;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _initialized = true;
    debugPrint('[PushNotification] Service initialized');
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const taskChannel = AndroidNotificationChannel(
      'task_notifications',
      'Task Notifications',
      description: 'Notifications for task updates',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(chatChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(taskChannel);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[PushNotification] Notification tapped: ${response.payload}');
    // Call the callback if set
    if (onNotificationTapped != null) {
      onNotificationTapped!(response.payload);
    }
  }

  /// Show a notification for a chat message
  static Future<void> showChatNotification(AppNotification notification) async {
    if (!_initialized) {
      await initialize();
    }

    // Don't show notification if user is viewing that chat
    // This will be handled by checking app state in the caller

    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        notification.message,
        contentTitle: notification.title,
        summaryText: notification.taskId != null
            ? 'Даалгаврын мессеж'
            : 'Төслийн мессеж',
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use notification ID as a unique identifier
    final notificationId = notification.id.hashCode;

    // Payload for navigation when tapped - use JSON-like string format
    final payload =
        '{"type":"chatMessage","projectId":"${notification.projectId ?? ''}","taskId":"${notification.taskId ?? ''}","barilgiinId":"${notification.barilgiinId}","baiguullagiinId":"${notification.baiguullagiinId}"}';

    await _notifications.show(
      notificationId,
      notification.title,
      notification.message,
      details,
      payload: payload,
    );

    debugPrint(
      '[PushNotification] Showed chat notification: ${notification.id}',
    );
  }

  /// Show a notification for task updates
  static Future<void> showTaskNotification(AppNotification notification) async {
    if (!_initialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for task updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = notification.id.hashCode;
    final payload = {
      'type': notification.turul,
      'projectId': notification.projectId,
      'taskId': notification.taskId,
    };

    await _notifications.show(
      notificationId,
      notification.title,
      notification.message,
      details,
      payload: payload.toString(),
    );

    debugPrint(
      '[PushNotification] Showed task notification: ${notification.id}',
    );
  }

  /// Show notification based on type
  static Future<void> showNotification(AppNotification notification) async {
    if (notification.turul == 'chatMessage') {
      await showChatNotification(notification);
    } else {
      await showTaskNotification(notification);
    }
  }

  /// Cancel a notification
  static Future<void> cancel(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications count
  static Future<int> getPendingCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }
}
