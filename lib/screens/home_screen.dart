import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Model for device info
class DeviceData {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final Timestamp lastSeen;
  final String fcmToken;

  DeviceData({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.lastSeen,
    required this.fcmToken,
  });

  factory DeviceData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeviceData(
      id: doc.id,
      name: data['name'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      lastSeen: data['lastSeen'] ?? Timestamp.now(),
      fcmToken: data['fcmToken'] ?? '',
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    _listenFCM();
  }

  void _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initializationSettings);
  }

  void _listenFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'Ping',
          message.notification!.body ?? 'Your device is being tracked.',
        );
      }
    });
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'findmate_channel',
      'FindMate Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(0, title, body, notificationDetails);
  }

  Future<void> _sendPing(DeviceData device) async {
    // Send FCM message to device's token via Firestore trigger or Cloud Function.
    // For MVP, we write a "ping" doc to Firestore and let the device listen for it.
    // If you have server-side FCM, send directly.
    final pingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('devices')
        .doc(device.id)
        .collection('pings')
        .doc();
    await pingRef.set({
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Your device is being tracked.',
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ping sent!')),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('FindMate Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('devices')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No devices found.'));
          }
          final devices = docs.map((doc) => DeviceData.fromFirestore(doc)).toList();
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('Last seen: ${device.lastSeen.toDate()}'),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 180,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(device.latitude, device.longitude),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(device.id),
                              position: LatLng(device.latitude, device.longitude),
                              infoWindow: InfoWindow(title: device.name),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationEnabled: false,
                          liteModeEnabled: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.notifications),
                            label: const Text('Ping'),
                            onPressed: () => _sendPing(device),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Simple privacy message
      bottomNavigationBar: Container(
        color: Colors.blue.shade50,
        padding: const EdgeInsets.all(8),
        child: const Text(
          'Location is shared securely with your account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
