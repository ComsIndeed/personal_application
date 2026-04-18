import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/app_prefs.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/database/database_utils.dart';
import '../../core/database/app_database.dart';
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
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  void _checkUser() {
    try {
      setState(() => _user = Supabase.instance.client.auth.currentUser);
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
      SyncService().start(context.read<AppDatabase>());
    } catch (e) {
      setState(
        () => _authError = e.toString().replaceAll('AuthException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    SyncService().stop();
    await Supabase.instance.client.auth.signOut();
    _checkUser();
  }

  Future<void> _requestSync(
    Future<void> Function() action,
    String title,
    String message,
    String successMsg,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _isSyncing = true);
    try {
      await action();
      if (mounted) {
        setState(() {}); // Refresh tiles
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Profile & Cloud Sync Area
        _buildSectionHeader('Cloud Account'),
        _buildSectionContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _user != null ? _buildUserPanel() : _buildAuthForm(),
        ),

        if (_user != null) ...[const SizedBox(height: 8), _buildSyncArea()],

        const SizedBox(height: 20),
        _buildSectionHeader('AI Providers'),
        _buildSectionContainer(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ProviderApiKeyTile(
                provider: LLMProvider.gemini,
                label: 'Gemini',
              ),
              const Divider(height: 1, color: Colors.white10),
              _ProviderApiKeyTile(
                provider: LLMProvider.deepseek,
                label: 'DeepSeek',
              ),
              const Divider(height: 1, color: Colors.white10),
              _ProviderApiKeyTile(provider: LLMProvider.groq, label: 'Groq'),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionHeader('Storage (Backblaze B2)'),
        const _B2CredentialsTile(),

        const SizedBox(height: 20),
        _buildSectionHeader('Data & Storage'),
        _buildSectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.table_chart_outlined,
                    size: 16,
                    color: Colors.white24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Database Browser',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      'COMING SOON',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Browse all local tables, inspect rows, follow foreign keys, and manage cloud files — all in one place.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white30,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        if (_user != null) ...[
          const SizedBox(height: 32),
          Center(
            child: Opacity(
              opacity: 0.5,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Wipe Cloud Backup'),
                onPressed: _isSyncing ? null : _showWipeConfirmation,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showWipeConfirmation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Wipe'),
        content: const Text('Delete your cloud backup? Local keys stay safe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _isSyncing = true);
      try {
        await DatabaseUtils().deleteCloudSecrets();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cloud secrets wiped')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Wipe failed: $e')));
      } finally {
        if (mounted) setState(() => _isSyncing = false);
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSyncArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_moon_outlined,
                size: 14,
                color: Colors.white38,
              ),
              const SizedBox(width: 8),
              Text(
                'Security Backup'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Backup',
                  icon: Icons.upload_rounded,
                  onPressed: () => _requestSync(
                    DatabaseUtils().uploadSecrets,
                    'Upload Secrets',
                    'This will overwrite your current cloud backup. Continue?',
                    'Secrets backed up',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  label: 'Restore',
                  icon: Icons.download_rounded,
                  color: Colors.greenAccent,
                  onPressed: () => _requestSync(
                    DatabaseUtils().loadSecrets,
                    'Restore Secrets',
                    'This will overwrite your local keys with the cloud backup. Continue?',
                    'Secrets restored',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSyncing ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (color ?? theme.colorScheme.primary).withValues(
                alpha: 0.15,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color ?? theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color ?? theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      children: [
        _buildLargeField(
          _emailController,
          'Account Email',
          Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 12),
        _buildLargeField(
          _passwordController,
          'Account Password',
          Icons.lock_rounded,
          obscure: true,
        ),
        if (_authError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _authError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPrimaryButton(
                label: 'Log In',
                onPressed: _isAuthLoading ? null : () => _handleAuth(true),
                isLoading: _isAuthLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryButton(
                label: 'Sign Up',
                onPressed: _isAuthLoading ? null : () => _handleAuth(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 30,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: Colors.white10, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildUserPanel() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _user?.email ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const Text(
                'Supabase Connected',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildIconButton(
          Icons.logout_rounded,
          _handleSignOut,
          color: Colors.redAccent.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color ?? Colors.white24),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.03),
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ProviderApiKeyTile extends StatefulWidget {
  final LLMProvider provider;
  final String label;

  const _ProviderApiKeyTile({required this.provider, required this.label});

  @override
  State<_ProviderApiKeyTile> createState() => _ProviderApiKeyTileState();
}

class _ProviderApiKeyTileState extends State<_ProviderApiKeyTile> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _count;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    final key = _getApiKey();
    if (key.isNotEmpty) _fetchModels();
  }

  String _getApiKey() {
    switch (widget.provider) {
      case LLMProvider.gemini:
        return AppPrefs().geminiApiKey;
      case LLMProvider.deepseek:
        return AppPrefs().deepSeekApiKey;
      case LLMProvider.groq:
        return AppPrefs().groqApiKey;
    }
  }

  Future<void> _fetchModels({bool force = false}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final models = await LLMService().listModels(
        widget.provider,
        force: force,
      );
      if (mounted)
        setState(() {
          _isActive = true;
          _isLoading = false;
          _count = '${models.length} Models';
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _isActive = false;
          _isLoading = false;
          _count = 'Off';
        });
    }
  }

  Future<void> _save() async {
    final val = _controller.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _isSaving = true;
    });
    switch (widget.provider) {
      case LLMProvider.gemini:
        AppPrefs().geminiApiKey = val;
        break;
      case LLMProvider.deepseek:
        AppPrefs().deepSeekApiKey = val;
        break;
      case LLMProvider.groq:
        AppPrefs().groqApiKey = val;
        break;
    }
    _controller.clear();
    await _fetchModels(force: true);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final btnLabel = (_controller.text.isEmpty && _isActive && _count != null)
        ? _count!
        : 'Update';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              obscureText: true,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: const TextStyle(
                  color: Colors.white24,
                  fontSize: 13,
                ),
                hintText: 'Paste key...',
                hintStyle: const TextStyle(color: Colors.white10),
                contentPadding: const EdgeInsets.symmetric(vertical: 30),
                border: InputBorder.none,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (_isSaving || _isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _save,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    btnLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _isActive && _controller.text.isEmpty
                          ? Colors.greenAccent
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _B2CredentialsTile extends StatefulWidget {
  const _B2CredentialsTile();

  @override
  State<_B2CredentialsTile> createState() => _B2CredentialsTileState();
}

class _B2CredentialsTileState extends State<_B2CredentialsTile> {
  final _kId = TextEditingController();
  final _aKey = TextEditingController();
  final _end = TextEditingController();
  final _buck = TextEditingController();
  bool _isSaving = false;
  bool _isVerifying = false;
  bool _isVerified = false;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _isVerified = StorageService().isLastVerified;
    _sub = StorageService().isVerifiedStream.listen((val) {
      if (mounted) setState(() => _isVerified = val);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _kId.dispose();
    _aKey.dispose();
    _end.dispose();
    _buck.dispose();
    super.dispose();
  }

  Future<void> _verifyOnly() async {
    setState(() => _isVerifying = true);
    try {
      await StorageService().verifyCredentials();
      if (mounted) {
        setState(() => _isVerified = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('B2 Connection Verified')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerified = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification Failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (_kId.text.isNotEmpty) AppPrefs().b2KeyId = _kId.text;
      if (_aKey.text.isNotEmpty) AppPrefs().b2AppKey = _aKey.text;
      if (_end.text.isNotEmpty) AppPrefs().b2Endpoint = _end.text;
      if (_buck.text.isNotEmpty) AppPrefs().b2BucketName = _buck.text;

      // Verify connection
      await StorageService().verifyCredentials();

      if (mounted) {
        setState(() => _isVerified = true);
        _kId.clear();
        _aKey.clear();
        _end.clear();
        _buck.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('B2 Verified & Saved')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerified = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification Failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _isVerified ? Colors.greenAccent : Colors.orangeAccent;
    final statusLabel = _isVerified ? 'VERIFIED' : 'UNVERIFIED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Service Config',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _isVerifying ? null : _verifyOnly,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              )
                            : Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: statusColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _largeInput(_kId, 'Key ID', Icons.vpn_key_rounded),
                const SizedBox(height: 10),
                _largeInput(
                  _aKey,
                  'App Key',
                  Icons.security_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 10),
                _largeInput(_end, 'S3 Endpoint', Icons.lan_rounded),
                const SizedBox(height: 10),
                _largeInput(_buck, 'Bucket', Icons.storage_rounded),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: InkWell(
              onTap: _isSaving ? null : _save,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _isSaving
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Text(
                        'VERIFY & SAVE CONFIG',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2.0,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _largeInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 11),
          prefixIcon: Icon(icon, size: 16, color: Colors.white24),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
