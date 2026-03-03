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
      '@drawable/ic_notification',
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

    // Request notification permission (required for Android 13+)
    await requestPermission();

    _initialized = true;
    debugPrint('[PushNotification] Service initialized');
  }

  /// Request notification permission (required for Android 13+ / API 33+)
  static Future<bool> requestPermission() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        debugPrint('[PushNotification] Permission granted: $granted');
        return granted ?? false;
      }

      // For iOS, permissions are requested automatically via DarwinInitializationSettings
      debugPrint(
        '[PushNotification] Permission check skipped (iOS or older Android)',
      );
      return true;
    } catch (e) {
      debugPrint('[PushNotification] Error requesting permission: $e');
      return false;
    }
  }

  /// Check if notification permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        debugPrint('[PushNotification] Permission status: $granted');
        return granted ?? false;
      }

      return true; // Assume granted for iOS or older Android
    } catch (e) {
      debugPrint('[PushNotification] Error checking permission: $e');
      return false;
    }
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
      importance: Importance.high, // Changed to high for better visibility
      playSound: true,
      enableVibration: true,
      showBadge: true,
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

    // Check permission before showing
    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      debugPrint(
        '[PushNotification] ⚠️ Permission not granted for chat notification, requesting...',
      );
      final granted = await requestPermission();
      if (!granted) {
        debugPrint(
          '[PushNotification] ❌ Cannot show chat notification: permission denied',
        );
        return;
      }
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
      icon: '@drawable/ic_notification',
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

    // Check permission before showing
    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      debugPrint(
        '[PushNotification] ⚠️ Permission not granted for task notification, requesting...',
      );
      final granted = await requestPermission();
      if (!granted) {
        debugPrint(
          '[PushNotification] ❌ Cannot show task notification: permission denied',
        );
        return;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for task updates',
      importance: Importance.high, // Changed to high for better visibility
      priority: Priority.high, // Changed to high priority
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification',
      styleInformation: BigTextStyleInformation(
        notification.message,
        contentTitle: notification.title,
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
    // Check permission before showing
    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      debugPrint('[PushNotification] ⚠️ Permission not granted, requesting...');
      final granted = await requestPermission();
      if (!granted) {
        debugPrint(
          '[PushNotification] ❌ Cannot show notification: permission denied',
        );
        return;
      }
    }

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

  /// Test notification - useful for debugging
  static Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      debugPrint('[PushNotification] ⚠️ Permission not granted, requesting...');
      final granted = await requestPermission();
      if (!granted) {
        debugPrint(
          '[PushNotification] ❌ Cannot show test notification: permission denied',
        );
        return;
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notifications for task updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999999, // Test notification ID
      'Тест мэдэгдэл',
      'Хэрэв та энэ мэдэгдлийг харж байгаа бол мэдэгдлийн систем ажиллаж байна.',
      details,
    );

    debugPrint('[PushNotification] ✅ Test notification shown');
  }
}
