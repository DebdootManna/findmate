import 'package:flutter/material.dart';

/// A simple widget to display privacy information at the bottom of the app.
class PrivacyMessage extends StatelessWidget {
  const PrivacyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(8),
      child: const Text(
        'Location is shared securely with your account.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      ),
    );
  }
}
