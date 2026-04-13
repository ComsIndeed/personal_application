import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Account',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Connect Google Account'),
          trailing: ElevatedButton(
            onPressed: () {},
            child: const Text('Login'),
          ),
        ),
        const Divider(height: 40),
        // Empty space for later
      ],
    );
  }
}
