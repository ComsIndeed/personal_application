import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/app_prefs.dart';
import '../../core/services/llm_service.dart';
import '../../core/database/database_utils.dart';
import '../../core/models/message/enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isAuthLoading = false;
  String? _authError;
  User? _user;

  // Global sync state
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() {
    try {
      setState(() {
        _user = Supabase.instance.client.auth.currentUser;
      });
    } catch (_) {}
  }

  Future<void> _handleAuth(bool isSignIn) async {
    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });

    try {
      if (isSignIn) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      _checkUser();
    } catch (e) {
      setState(() {
        _authError = e.toString().replaceAll('AuthException: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      _checkUser();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> _uploadToCloud() async {
    setState(() => _isSyncing = true);
    try {
      await DatabaseUtils().uploadSecrets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secrets uploaded to cloud')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadFromCloud() async {
    setState(() => _isSyncing = true);
    try {
      await DatabaseUtils().loadSecrets();
      // We need to trigger a rebuild of all tiles to show the new "active" status
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secrets loaded from cloud')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Load failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _deleteCloudSecrets() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cloud Secrets?'),
        content: const Text(
          'This will permanently remove your stored keys from Supabase. Your local keys will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSyncing = true);
    try {
      await DatabaseUtils().deleteCloudSecrets();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cloud secrets deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          color: isDark ? const Color(0xFF0B1120) : theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : theme.dividerColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _user != null ? _buildUserPanel() : _buildAuthForm(),
          ),
        ),

        if (_user != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Cloud Sync',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCloudSyncCard(),
        ],

        Divider(
          height: 48,
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
        ),
        const Text(
          'AI Providers',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ProviderApiKeyTile(
          provider: LLMProvider.gemini,
          label: 'Gemini API Key',
          hint: 'Paste new key...',
        ),
        const SizedBox(height: 12),
        ProviderApiKeyTile(
          provider: LLMProvider.deepseek,
          label: 'DeepSeek API Key',
          hint: 'Paste new key...',
        ),
        const SizedBox(height: 12),
        ProviderApiKeyTile(
          provider: LLMProvider.groq,
          label: 'Groq API Key',
          hint: 'Paste new key...',
        ),
        const SizedBox(height: 24),
        const Text(
          'Storage (Backblaze B2)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const B2CredentialsTile(),

        Divider(
          height: 48,
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
        ),
        const Text(
          'App Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_user != null)
          ListTile(
            leading: const Icon(
              Icons.cloud_off_outlined,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Delete Cloud Secrets',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text('Remove your data from Supabase'),
            onTap: _isSyncing ? null : _deleteCloudSecrets,
          ),
        SwitchListTile(
          value: true,
          onChanged: (v) {},
          title: const Text('Enable Notifications'),
          secondary: const Icon(Icons.notifications_outlined),
        ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: const Text('Clear Local Cache'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About Universal Hub'),
          subtitle: const Text('Version 1.1.0'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildCloudSyncCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0B1120) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Securely backup your keys to your private cloud storage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _uploadToCloud,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: theme.colorScheme.primary,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _loadFromCloud,
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('Load'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: Colors.greenAccent,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.email_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Password',
            prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
          ),
        ),
        if (_authError != null) ...[
          const SizedBox(height: 8),
          Text(
            _authError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isAuthLoading ? null : () => _handleAuth(true),
                child: _isAuthLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _isAuthLoading ? null : () => _handleAuth(false),
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Icon(
          Icons.account_circle_outlined,
          size: 48,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
        const SizedBox(height: 12),
        Text(
          _user?.email ?? 'Logged In',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Cloud sync enabled',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            onPressed: _handleSignOut,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
        ),
      ],
    );
  }
}

class ProviderApiKeyTile extends StatefulWidget {
  final LLMProvider provider;
  final String label;
  final String hint;

  const ProviderApiKeyTile({
    super.key,
    required this.provider,
    required this.label,
    required this.hint,
  });

  @override
  State<ProviderApiKeyTile> createState() => _ProviderApiKeyTileState();
}

class _ProviderApiKeyTileState extends State<ProviderApiKeyTile> {
  final TextEditingController _controller = TextEditingController();
  List<String> _models = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    final key = _getApiKeyFromPrefs();
    if (key.isNotEmpty) {
      setState(() => _isActive = true);
      _fetchModels();
    } else {
      setState(() => _isActive = false);
    }
  }

  String _getApiKeyFromPrefs() {
    switch (widget.provider) {
      case LLMProvider.gemini:
        return AppPrefs().geminiApiKey;
      case LLMProvider.deepseek:
        return AppPrefs().deepSeekApiKey;
      case LLMProvider.groq:
        return AppPrefs().groqApiKey;
    }
  }

  Future<void> _fetchModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final models = await LLMService().listModels(widget.provider);
      if (mounted) {
        setState(() {
          _models = models;
          _isLoading = false;
          _isActive = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Verification failed';
          _isLoading = false;
          _isActive = false;
          _models = [];
        });
      }
    }
  }

  Future<void> _saveLocally() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;

    setState(() => _isSaving = true);

    // Temporarily set the key to verify it
    final oldKey = _getApiKeyFromPrefs();
    _setApiKeyInPrefs(value);

    try {
      final models = await LLMService().listModels(widget.provider);
      if (mounted) {
        setState(() {
          _models = models;
          _isSaving = false;
          _isActive = true;
          _error = null;
        });
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.label} saved locally')),
        );
      }
    } catch (e) {
      // Revert if failed
      _setApiKeyInPrefs(oldKey);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Invalid API key';
        });
      }
    }
  }

  void _setApiKeyInPrefs(String value) {
    switch (widget.provider) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0B1120) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (_isActive)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isSaving || _isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: _saveLocally,
                    child: const Text('Save Locally'),
                  ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
              )
            else if (_models.isNotEmpty)
              Text(
                'Models: ${_models.take(3).join(", ")}...',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class B2CredentialsTile extends StatefulWidget {
  const B2CredentialsTile({super.key});

  @override
  State<B2CredentialsTile> createState() => _B2CredentialsTileState();
}

class _B2CredentialsTileState extends State<B2CredentialsTile> {
  final _keyIdController = TextEditingController();
  final _appKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _bucketController = TextEditingController();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    if (AppPrefs().b2KeyId.isNotEmpty) {
      setState(() => _isSaved = true);
    }
  }

  void _saveLocally() {
    if (_keyIdController.text.isNotEmpty)
      AppPrefs().b2KeyId = _keyIdController.text;
    if (_appKeyController.text.isNotEmpty)
      AppPrefs().b2AppKey = _appKeyController.text;
    if (_endpointController.text.isNotEmpty)
      AppPrefs().b2Endpoint = _endpointController.text;
    if (_bucketController.text.isNotEmpty)
      AppPrefs().b2BucketName = _bucketController.text;

    _keyIdController.clear();
    _appKeyController.clear();
    _endpointController.clear();
    _bucketController.clear();

    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('B2 credentials saved locally')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0B1120) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Credentials',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (_isSaved)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 14,
                  ),
              ],
            ),
            TextField(
              controller: _keyIdController,
              decoration: const InputDecoration(
                hintText: 'Key ID',
                isDense: true,
              ),
            ),
            TextField(
              controller: _appKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Application Key',
                isDense: true,
              ),
            ),
            TextField(
              controller: _endpointController,
              decoration: const InputDecoration(
                hintText: 'Endpoint (e.g. s3.us-west-004.backblazeb2.com)',
                isDense: true,
              ),
            ),
            TextField(
              controller: _bucketController,
              decoration: const InputDecoration(
                hintText: 'Bucket Name',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLocally,
                child: const Text('Save Locally'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
