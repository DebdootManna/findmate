findmate/lib/widgets/device_card.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// DeviceCard widget displays device info, last seen, and location on a map.
/// Used in the device list on HomeScreen.
class DeviceCard extends StatelessWidget {
  final String deviceName;
  final DateTime lastSeen;
  final double latitude;
  final double longitude;
  final VoidCallback onPing;

  const DeviceCard({
    Key? key,
    required this.deviceName,
    required this.lastSeen,
    required this.latitude,
    required this.longitude,
    required this.onPing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('Last seen: ${lastSeen.toLocal()}'),
            const SizedBox(height: 4),
            SizedBox(
              height: 180,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('device_marker'),
                    position: LatLng(latitude, longitude),
                    infoWindow: InfoWindow(title: deviceName),
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
                  onPressed: onPing,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
