import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

/// DeviceService handles device registration and Firestore sync for FindMate.
/// Each device is registered under the user's UID in Firestore.
/// Device info includes: deviceId, deviceName, platform, lastSeen, location, fcmToken.
class DeviceService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _devicesCollection = _firestore.collection('devices');
  static String? _deviceId;

  /// Returns the unique device ID (UUID or platform-specific).
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      // For web, use a random UUID (not persistent)
      _deviceId = const Uuid().v4();
    } else if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      _deviceId = info.serialNumber;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      _deviceId = info.identifierForVendor ?? const Uuid().v4();
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      _deviceId = info.systemGUID ?? const Uuid().v4();
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      _deviceId = info.deviceId;
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      _deviceId = info.machineId ?? const Uuid().v4();
    } else {
      _deviceId = const Uuid().v4();
    }
    return _deviceId!;
  }

  /// Returns a human-readable device name.
  static Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      return "Web Browser";
    } else if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return "${info.manufacturer} ${info.model}";
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return "${info.name} (${info.model})";
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      return "${info.computerName} (macOS)";
    } else if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      return "${info.computerName} (Windows)";
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      return "${info.name} (Linux)";
    } else {
      return "Unknown Device";
    }
  }

  /// Registers or updates this device in Firestore under the current user's UID.
  /// Stores device info, last seen timestamp, and optionally location/fcmToken.
  static Future<void> registerDevice({
    required Map<String, dynamic> location,
    String? fcmToken,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();
    final platform = _getPlatform();
    final now = DateTime.now().toUtc();

    await _devicesCollection
        .doc(user.uid)
        .collection('user_devices')
        .doc(deviceId)
        .set({
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'lastSeen': now,
      'location': location,
      'fcmToken': fcmToken,
    }, SetOptions(merge: true));
  }

  /// Returns a stream of all devices registered under the current user's UID.
  static Stream<List<Map<String, dynamic>>> getUserDevicesStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _devicesCollection
        .doc(user.uid)
        .collection('user_devices')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Helper to get platform name.
  static String _getPlatform() {
    if (kIsWeb) return "Web";
    if (Platform.isAndroid) return "Android";
    if (Platform.isIOS) return "iOS";
    if (Platform.isMacOS) return "macOS";
    if (Platform.isWindows) return "Windows";
    if (Platform.isLinux) return "Linux";
    return "Unknown";
  }
}
