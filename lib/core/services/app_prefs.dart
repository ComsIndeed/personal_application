import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static final AppPrefs _instance = AppPrefs._internal();
  factory AppPrefs() => _instance;
  AppPrefs._internal();

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Cache for secure values to support synchronous getters
  String _geminiApiKey = '';
  String _deepSeekApiKey = '';
  String _groqApiKey = '';
  String _b2KeyId = '';
  String _b2AppKey = '';
  String _b2Endpoint = '';
  String _b2BucketName = '';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await reloadAll();
  }

  Future<void> reloadAll() async {
    // Load secure values into cache
    _geminiApiKey = await _secureStorage.read(key: 'gemini_api_key') ?? '';
    _deepSeekApiKey = await _secureStorage.read(key: 'deepseek_api_key') ?? '';
    _groqApiKey = await _secureStorage.read(key: 'groq_api_key') ?? '';
    _b2KeyId = await _secureStorage.read(key: 'b2_key_id') ?? '';
    _b2AppKey = await _secureStorage.read(key: 'b2_app_key') ?? '';
    _b2Endpoint = await _secureStorage.read(key: 'b2_endpoint') ?? '';
    _b2BucketName = await _secureStorage.read(key: 'b2_bucket_name') ?? '';
  }

  Future<void> clearAll() async {
    await _secureStorage.delete(key: 'gemini_api_key');
    await _secureStorage.delete(key: 'deepseek_api_key');
    await _secureStorage.delete(key: 'groq_api_key');
    await _secureStorage.delete(key: 'b2_key_id');
    await _secureStorage.delete(key: 'b2_app_key');
    await _secureStorage.delete(key: 'b2_endpoint');
    await _secureStorage.delete(key: 'b2_bucket_name');
    _geminiApiKey = '';
    _deepSeekApiKey = '';
    _groqApiKey = '';
    _b2KeyId = '';
    _b2AppKey = '';
    _b2Endpoint = '';
    _b2BucketName = '';
  }

  // --- Secure Storage Helpers ---

  Future<void> _setSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  // --- Standard Preferences Helpers ---

  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  void setBool(String key, bool value) {
    _prefs.setBool(key, value);
  }

  // --- Specific Getters/Setters (Secure with Cache) ---

  String get geminiApiKey => _geminiApiKey;
  set geminiApiKey(String value) {
    _geminiApiKey = value;
    _setSecure('gemini_api_key', value);
  }

  String get deepSeekApiKey => _deepSeekApiKey;
  set deepSeekApiKey(String value) {
    _deepSeekApiKey = value;
    _setSecure('deepseek_api_key', value);
  }

  String get groqApiKey => _groqApiKey;
  set groqApiKey(String value) {
    _groqApiKey = value;
    _setSecure('groq_api_key', value);
  }

  String get b2KeyId => _b2KeyId;
  String get b2AppKey => _b2AppKey;
  String get b2Endpoint => _b2Endpoint;
  String get b2BucketName => _b2BucketName;

  Future<void> saveB2Credentials({
    required String keyId,
    required String appKey,
    required String endpoint,
    required String bucketName,
  }) async {
    _b2KeyId = keyId.trim();
    _b2AppKey = appKey.trim();
    _b2Endpoint = endpoint.trim();
    _b2BucketName = bucketName.trim();

    await Future.wait([
      _setSecure('b2_key_id', _b2KeyId),
      _setSecure('b2_app_key', _b2AppKey),
      _setSecure('b2_endpoint', _b2Endpoint),
      _setSecure('b2_bucket_name', _b2BucketName),
    ]);
  }

  // --- Experimental Features ---

  bool get dynamicBackdropEnabled =>
      getBool('dynamic_backdrop_enabled', defaultValue: true);
  set dynamicBackdropEnabled(bool value) =>
      setBool('dynamic_backdrop_enabled', value);
}
