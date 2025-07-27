findmate/lib/models/device.dart
/// Device model for FindMate app.
/// Stores device info, location, and last seen timestamp.

import 'package:cloud_firestore/cloud_firestore.dart';

class Device {
  final String id; // Unique device ID (UUID or device name)
  final String name; // Human-readable device name
  final String platform; // 'android', 'macos', etc.
  final double latitude;
  final double longitude;
  final DateTime lastSeen;
  final String? fcmToken; // For push notifications

  Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.latitude,
    required this.longitude,
    required this.lastSeen,
    this.fcmToken,
  });

  /// Factory constructor to create Device from Firestore document.
  factory Device.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Device(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      platform: data['platform'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'],
    );
  }

  /// Convert Device to Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'fcmToken': fcmToken,
    };
  }
}
