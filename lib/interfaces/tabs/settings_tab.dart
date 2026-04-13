import 'package:flutter/material.dart';
import '../../core/services/app_prefs.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Account & Auth',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white10)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(fontSize: 12, color: Colors.white24),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white10)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: const Text('Google'),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.code_rounded),
                        label: const Text('GitHub'),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 48, color: Colors.white10),
        const Text(
          'AI Providers',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildApiKeyField(
          label: 'Gemini API Key',
          hint: 'Enter Gemini API Key',
          value: AppPrefs().geminiApiKey,
          onChanged: (v) => AppPrefs().geminiApiKey = v,
        ),
        const SizedBox(height: 12),
        _buildApiKeyField(
          label: 'DeepSeek API Key',
          hint: 'Enter DeepSeek API Key',
          value: AppPrefs().deepSeekApiKey,
          onChanged: (v) => AppPrefs().deepSeekApiKey = v,
        ),
        const SizedBox(height: 12),
        _buildApiKeyField(
          label: 'Groq API Key',
          hint: 'Enter Groq API Key',
          value: AppPrefs().groqApiKey,
          onChanged: (v) => AppPrefs().groqApiKey = v,
        ),
        const Divider(height: 48, color: Colors.white10),
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

  Widget _buildApiKeyField({
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            TextField(
              obscureText: true,
              controller: TextEditingController(text: value)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length),
                ),
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
