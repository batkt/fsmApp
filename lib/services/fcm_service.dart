import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/notification_model.dart';
import 'push_notification_service.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Firebase Cloud Messaging service
/// Handles FCM tokens and remote notifications
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static bool _initialized = false;

  /// Initialize FCM service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint('[FCM] FCM Token: $_fcmToken');

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('[FCM] Token refreshed: $newToken');
          // Re-register token with backend
          registerTokenWithBackend(newToken);
        });

        // Register initial token with backend
        if (_fcmToken != null) {
          await registerTokenWithBackend(_fcmToken!);
        }

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message taps (when app is opened from notification)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

        // Check if app was opened from a notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpened(initialMessage);
        }

        _initialized = true;
        debugPrint('[FCM] Service initialized successfully');
      } else {
        debugPrint('[FCM] Notification permission denied');
      }
    } catch (e) {
      debugPrint('[FCM] Error initializing: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Received foreground message: ${message.messageId}');

    // Convert RemoteMessage to AppNotification and show local notification
    try {
      final notification = _remoteMessageToAppNotification(message);
      if (notification != null) {
        await PushNotificationService.showNotification(notification);
      }
    } catch (e) {
      debugPrint('[FCM] Error handling foreground message: $e');
    }
  }

  /// Handle message opened (when user taps notification)
  static void _handleMessageOpened(RemoteMessage message) {
    debugPrint('[FCM] Message opened: ${message.messageId}');

    // Handle navigation based on notification data
    final data = message.data;

    // Create payload for navigation
    final payload =
        '{"type":"${data['turul'] ?? data['type'] ?? 'medegdel'}","projectId":"${data['projectId'] ?? ''}","taskId":"${data['taskId'] ?? ''}","barilgiinId":"${data['barilgiinId'] ?? ''}","baiguullagiinId":"${data['baiguullagiinId'] ?? ''}"}';

    // Use PushNotificationService handler if available
    if (PushNotificationService.onNotificationTapped != null) {
      PushNotificationService.onNotificationTapped!(payload);
    } else {
      debugPrint('[FCM] ⚠️ No notification tap handler registered');
    }
  }

  /// Convert RemoteMessage to AppNotification
  static AppNotification? _remoteMessageToAppNotification(
    RemoteMessage message,
  ) {
    try {
      final data = message.data;
      final notification = message.notification;

      return AppNotification(
        id:
            data['notificationId'] ??
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        ajiltniiId: data['ajiltniiId'] ?? '',
        baiguullagiinId: data['baiguullagiinId'] ?? '',
        barilgiinId: data['barilgiinId'] ?? '',
        projectId: data['projectId'],
        taskId: data['taskId'],
        turul: data['turul'] ?? 'medegdel',
        title: notification?.title ?? data['title'] ?? 'Мэдэгдэл',
        message: notification?.body ?? data['message'] ?? '',
        kharsanEsekh:
            data['kharsanEsekh'] == 'true' || data['kharsanEsekh'] == true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[FCM] Error converting RemoteMessage: $e');
      return null;
    }
  }

  /// Get FCM token (for sending to backend)
  static String? getToken() => _fcmToken;

  /// Register FCM token with backend
  /// Works even when user is not logged in - just needs ajiltniiId
  static Future<void> registerTokenWithBackend(String token) async {
    try {
      // Get user ID (can be from AuthService or stored separately)
      final user = AuthService.currentUser;
      final ajiltniiId = user?.id;

      if (ajiltniiId == null || ajiltniiId.isEmpty) {
        debugPrint('[FCM] ⚠️ Cannot register token: No user ID available');
        debugPrint(
          '[FCM] Note: Token registration works even when not logged in - just needs ajiltniiId',
        );
        return;
      }

      // Get app version
      String appVersion = '1.0.0';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
      } catch (e) {
        debugPrint('[FCM] Could not get app version: $e');
      }

      // Get device type
      final deviceType = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : 'unknown';

      // Prepare registration payload
      final payload = {
        'ajiltniiId': ajiltniiId,
        'token': token,
        'deviceType': deviceType,
        'appVersion': appVersion,
      };

      // Add optional fields if available
      if (user?.baiguullagaId != null && user!.baiguullagaId.isNotEmpty) {
        payload['baiguullagiinId'] = user.baiguullagaId;
      }

      debugPrint('[FCM] Registering token with backend: $token');
      debugPrint('[FCM] Payload: $payload');

      // Register with backend
      final result = await ApiService.post('/fcm/register', body: payload);

      if (result.success) {
        debugPrint('[FCM] ✅ Token registered successfully');
      } else {
        debugPrint(
          '[FCM] ❌ Failed to register token: ${result.message ?? "Unknown error"}',
        );
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Error registering token: $e');
    }
  }

  /// Deactivate FCM token (on logout)
  static Future<void> deactivateToken() async {
    try {
      final token = _fcmToken;
      if (token == null) return;

      debugPrint('[FCM] Deactivating token: $token');

      final result = await ApiService.put(
        '/fcm/deactivate',
        body: {'token': token},
      );

      if (result.success) {
        debugPrint('[FCM] ✅ Token deactivated successfully');
      } else {
        debugPrint(
          '[FCM] ❌ Failed to deactivate token: ${result.message ?? "Unknown error"}',
        );
      }
    } catch (e) {
      debugPrint('[FCM] ❌ Error deactivating token: $e');
    }
  }

  /// Delete FCM token (on logout)
  static Future<void> deleteToken() async {
    try {
      // Deactivate token with backend first
      await deactivateToken();

      // Then delete locally
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] Token deleted');
    } catch (e) {
      debugPrint('[FCM] Error deleting token: $e');
    }
  }

  /// Background message handler (must be top-level function)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint('[FCM] Background message received: ${message.messageId}');
    // Background messages are handled automatically by the system
    // We can process them here if needed
  }
}
