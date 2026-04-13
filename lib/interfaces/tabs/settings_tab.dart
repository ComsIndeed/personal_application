import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
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
        const Text(
          'App Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: true,
          onChanged: (v) {},
          title: const Text('Enable Notifications'),
          secondary: const Icon(Icons.notifications_outlined),
        ),
        SwitchListTile(
          value: false,
          onChanged: (v) {},
          title: const Text('Start at Login'),
          secondary: const Icon(Icons.login_outlined),
        ),
        ListTile(
          leading: const Icon(Icons.language_outlined),
          title: const Text('Language'),
          subtitle: const Text('English (US)'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Clear Cache'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About Universal Hub'),
          subtitle: const Text('Version 1.0.0'),
          onTap: () {},
        ),
      ],
    );
  }
}
