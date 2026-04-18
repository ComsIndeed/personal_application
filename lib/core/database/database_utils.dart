import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_prefs.dart';
import '../services/storage_service.dart';

class DatabaseUtils {
  final _supabase = Supabase.instance.client;
  final _prefs = AppPrefs();

  Future<void> uploadSecrets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Filter B2 data to only include non-empty values
    final b2Data = <String, dynamic>{};
    if (_prefs.b2KeyId.isNotEmpty) b2Data['keyId'] = _prefs.b2KeyId;
    if (_prefs.b2AppKey.isNotEmpty) b2Data['appKey'] = _prefs.b2AppKey;
    if (_prefs.b2Endpoint.isNotEmpty) b2Data['endpoint'] = _prefs.b2Endpoint;
    if (_prefs.b2BucketName.isNotEmpty)
      b2Data['bucketName'] = _prefs.b2BucketName;

    final Map<String, dynamic> data = {'user_id': user.id};

    // Only include b2 if it has data
    if (b2Data.isNotEmpty) {
      // First, fetch existing B2 data to merge it if we want to avoid accidental deletion
      final existing = await _supabase
          .from('secrets')
          .select('b2')
          .eq('user_id', user.id)
          .maybeSingle();
      if (existing != null && existing['b2'] != null) {
        final Map<String, dynamic> mergedB2 = Map<String, dynamic>.from(
          existing['b2'] as Map,
        );
        mergedB2.addAll(b2Data);
        data['b2'] = mergedB2;
      } else {
        data['b2'] = b2Data;
      }
    }

    if (_prefs.geminiApiKey.isNotEmpty) {
      data['gemini_api_key'] = _prefs.geminiApiKey;
    }
    if (_prefs.deepSeekApiKey.isNotEmpty) {
      data['deepseek_api_key'] = _prefs.deepSeekApiKey;
    }
    if (_prefs.groqApiKey.isNotEmpty) {
      data['groq_api_key'] = _prefs.groqApiKey;
    }

    await _supabase.from('secrets').upsert(data, onConflict: 'user_id');
  }

  Future<void> loadSecrets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final response = await _supabase
        .from('secrets')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return;

    if (response['gemini_api_key'] != null) {
      _prefs.geminiApiKey = response['gemini_api_key'];
    }
    if (response['deepseek_api_key'] != null) {
      _prefs.deepSeekApiKey = response['deepseek_api_key'];
    }
    if (response['groq_api_key'] != null) {
      _prefs.groqApiKey = response['groq_api_key'];
    }

    final b2 = response['b2'] as Map<String, dynamic>?;
    if (b2 != null) {
      if (b2['keyId'] != null) _prefs.b2KeyId = (b2['keyId'] as String).trim();
      if (b2['appKey'] != null)
        _prefs.b2AppKey = (b2['appKey'] as String).trim();
      if (b2['endpoint'] != null)
        _prefs.b2Endpoint = (b2['endpoint'] as String).trim();
      if (b2['bucketName'] != null)
        _prefs.b2BucketName = (b2['bucketName'] as String).trim();
    }

    // Trigger re-verification after storage settings are loaded
    StorageService().verifyCredentials().catchError((_) {});
  }

  Future<void> deleteCloudSecrets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('secrets').delete().eq('user_id', user.id);
  }
}
