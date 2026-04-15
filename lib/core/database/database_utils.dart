import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_prefs.dart';

class DatabaseUtils {
  final _supabase = Supabase.instance.client;
  final _prefs = AppPrefs();

  Future<void> uploadSecrets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final b2Data = {
      'keyId': _prefs.b2KeyId,
      'appKey': _prefs.b2AppKey,
      'endpoint': _prefs.b2Endpoint,
      'bucketName': _prefs.b2BucketName,
    };

    final Map<String, dynamic> data = {'user_id': user.id, 'b2': b2Data};

    if (_prefs.geminiApiKey.isNotEmpty) {
      data['gemini_api_key'] = _prefs.geminiApiKey;
    }
    if (_prefs.deepSeekApiKey.isNotEmpty) {
      data['deepseek_api_key'] = _prefs.deepSeekApiKey;
    }
    if (_prefs.groqApiKey.isNotEmpty) {
      data['groq_api_key'] = _prefs.groqApiKey;
    }

    await _supabase.from('secrets').upsert(data);
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
      if (b2['keyId'] != null) _prefs.b2KeyId = b2['keyId'];
      if (b2['appKey'] != null) _prefs.b2AppKey = b2['appKey'];
      if (b2['endpoint'] != null) _prefs.b2Endpoint = b2['endpoint'];
      if (b2['bucketName'] != null) _prefs.b2BucketName = b2['bucketName'];
    }

    await _prefs.reloadAll();
  }

  Future<void> deleteCloudSecrets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('secrets').delete().eq('user_id', user.id);
  }
}
