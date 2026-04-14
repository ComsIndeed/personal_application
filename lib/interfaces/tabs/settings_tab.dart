import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/app_prefs.dart';
import '../../core/services/llm_service.dart';
import '../../core/models/message/enums.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final Map<LLMProvider, List<String>> _models = {};
  final Map<LLMProvider, bool> _isLoading = {};
  final Map<LLMProvider, bool> _isSaving = {};
  final Map<LLMProvider, String?> _errors = {};
  final Map<LLMProvider, Timer?> _debounceTimers = {};

  @override
  void initState() {
    super.initState();
    _fetchAllModels();
  }

  @override
  void dispose() {
    for (var timer in _debounceTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  Future<void> _fetchAllModels() async {
    await Future.wait([
      _fetchModels(LLMProvider.gemini),
      _fetchModels(LLMProvider.deepseek),
      _fetchModels(LLMProvider.groq),
    ]);
  }

  Future<void> _fetchModels(LLMProvider provider) async {
    final apiKey = _getApiKey(provider);
    if (apiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _models[provider] = [];
          _errors[provider] = null;
          _isLoading[provider] = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading[provider] = true;
        _errors[provider] = null;
      });
    }

    try {
      final models = await LLMService().listModels(provider);
      if (mounted) {
        setState(() {
          _models[provider] = models;
          _isLoading[provider] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errors[provider] = 'Invalid API Key or connection error';
          _isLoading[provider] = false;
          _models[provider] = [];
        });
      }
    }
  }

  void _onApiKeyChanged(LLMProvider provider, String value) {
    _debounceTimers[provider]?.cancel();

    // Clear models/errors immediately if value is empty
    if (value.isEmpty) {
      setState(() {
        _models[provider] = [];
        _errors[provider] = null;
        _isLoading[provider] = false;
        _isSaving[provider] = false;
      });
      // Save the empty value immediately
      _saveValue(provider, value);
      return;
    }

    _debounceTimers[provider] = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (!mounted) return;

        setState(() {
          _isSaving[provider] = true;
          _models[provider] = []; // Reset on new key
          _errors[provider] = null;
        });

        // Save the key
        _saveValue(provider, value);

        // Visual beat for "Saving"
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        setState(() {
          _isSaving[provider] = false;
        });

        // Fetch models
        await _fetchModels(provider);
      },
    );
  }

  String _getApiKey(LLMProvider provider) {
    return switch (provider) {
      LLMProvider.gemini => AppPrefs().geminiApiKey,
      LLMProvider.deepseek => AppPrefs().deepSeekApiKey,
      LLMProvider.groq => AppPrefs().groqApiKey,
    };
  }

  void _saveValue(LLMProvider provider, String value) {
    switch (provider) {
      case LLMProvider.gemini:
        AppPrefs().geminiApiKey = value;
        break;
      case LLMProvider.deepseek:
        AppPrefs().deepSeekApiKey = value;
        break;
      case LLMProvider.groq:
        AppPrefs().groqApiKey = value;
        break;
    }
  }

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
          provider: LLMProvider.gemini,
          label: 'Gemini API Key',
          hint: 'Enter Gemini API Key',
          value: AppPrefs().geminiApiKey,
          onChanged: (v) => _onApiKeyChanged(LLMProvider.gemini, v),
        ),
        const SizedBox(height: 12),
        _buildApiKeyField(
          provider: LLMProvider.deepseek,
          label: 'DeepSeek API Key',
          hint: 'Enter DeepSeek API Key',
          value: AppPrefs().deepSeekApiKey,
          onChanged: (v) => _onApiKeyChanged(LLMProvider.deepseek, v),
        ),
        const SizedBox(height: 12),
        _buildApiKeyField(
          provider: LLMProvider.groq,
          label: 'Groq API Key',
          hint: 'Enter Groq API Key',
          value: AppPrefs().groqApiKey,
          onChanged: (v) => _onApiKeyChanged(LLMProvider.groq, v),
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
    required LLMProvider provider,
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final models = _models[provider] ?? [];
    final isLoading = _isLoading[provider] ?? false;
    final isSaving = _isSaving[provider] ?? false;
    final error = _errors[provider];

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (isSaving || isLoading)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isSaving ? 'Saving...' : 'Verifying...',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white54),
                        ),
                      ),
                    ],
                  )
                else if (models.isNotEmpty)
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Colors.greenAccent,
                  )
                else if (error != null)
                  const Icon(
                    Icons.error_outline,
                    size: 14,
                    color: Colors.redAccent,
                  ),
              ],
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
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  error,
                  style: const TextStyle(fontSize: 10, color: Colors.redAccent),
                ),
              )
            else if (models.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Connected: ${models.take(5).join(", ")}${models.length > 5 ? "..." : ""}',
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
