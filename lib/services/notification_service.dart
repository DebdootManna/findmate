findmate/lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM push notifications and local notifications.
/// Call [initialize] in your app's startup.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Call this once at app startup.
  Future<void> initialize() async {
    // Request notification permissions (especially for iOS/macOS)
    await _firebaseMessaging.requestPermission();

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onMessage);

    // Optionally handle background/terminated messages (see docs)
  }

  /// Returns the FCM token for this device.
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Show a local notification with [title] and [body].
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'findmate_channel',
      'FindMate Alerts',
      channelDescription: 'Notifications for FindMate device pings',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
    await _localNotifications.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  /// Handles incoming FCM messages when app is in foreground.
  void _onMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'Ping',
        body: notification.body ?? 'Your device is being tracked.',
      );
    }
  }
}
