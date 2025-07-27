findmate/lib/widgets/ping_listener.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Listens for ping events in Firestore and shows a local notification.
/// Should be placed near the root of the widget tree after login.
class PingListener extends StatefulWidget {
  final Widget child;
  final String deviceId;

  const PingListener({
    Key? key,
    required this.child,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<PingListener> createState() => _PingListenerState();
}

class _PingListenerState extends State<PingListener> {
  StreamSubscription<QuerySnapshot>? _pingSubscription;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _listenForPings();
  }

  void _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  void _listenForPings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.deviceId.isEmpty) return;

    final pingCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('devices')
        .doc(widget.deviceId)
        .collection('pings')
        .orderBy('timestamp', descending: true)
        .limit(1);

    _pingSubscription = pingCollection.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final ping = snapshot.docs.first.data();
        final message = ping['message'] ?? 'Your device is being tracked.';
        _showLocalNotification('Device Ping', message);
      }
    });
  }

  Future<void> _showLocalNotification(String title, String body) async {
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

  @override
  void dispose() {
    _pingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
