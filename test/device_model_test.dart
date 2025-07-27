import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findmate/models/device.dart';

void main() {
  group('Device Model', () {
    test('fromFirestore creates Device from document', () {
      final fakeData = {
        'id': 'device123',
        'name': 'MacBook Pro',
        'platform': 'macOS',
        'latitude': 12.34,
        'longitude': 56.78,
        'lastSeen': Timestamp.fromDate(DateTime(2024, 6, 1, 12, 0)),
        'fcmToken': 'token_abc',
      };
      final doc = _FakeDocumentSnapshot(fakeData);

      final device = Device.fromFirestore(doc);

      expect(device.id, 'device123');
      expect(device.name, 'MacBook Pro');
      expect(device.platform, 'macOS');
      expect(device.latitude, 12.34);
      expect(device.longitude, 56.78);
      expect(device.lastSeen, DateTime(2024, 6, 1, 12, 0));
      expect(device.fcmToken, 'token_abc');
    });

    test('toMap returns correct map', () {
      final device = Device(
        id: 'device456',
        name: 'Pixel 7',
        platform: 'android',
        latitude: 22.22,
        longitude: 33.33,
        lastSeen: DateTime(2024, 6, 2, 10, 30),
        fcmToken: 'token_xyz',
      );

      final map = device.toMap();

      expect(map['id'], 'device456');
      expect(map['name'], 'Pixel 7');
      expect(map['platform'], 'android');
      expect(map['latitude'], 22.22);
      expect(map['longitude'], 33.33);
      expect(map['lastSeen'], Timestamp.fromDate(DateTime(2024, 6, 2, 10, 30)));
      expect(map['fcmToken'], 'token_xyz');
    });
  });
}

/// Fake DocumentSnapshot for testing
class _FakeDocumentSnapshot implements DocumentSnapshot {
  final Map<String, dynamic> _data;
  _FakeDocumentSnapshot(this._data);

  @override
  dynamic get(String field) => _data[field];

  @override
  Map<String, dynamic> data() => _data;

  @override
  String get id => _data['id'] ?? 'fake_id';

  // The rest of the DocumentSnapshot interface is not needed for this test.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
