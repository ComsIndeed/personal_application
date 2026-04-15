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

  void setString(String key, String value) {
    _prefs.setString(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
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
  set b2KeyId(String value) {
    _b2KeyId = value;
    _setSecure('b2_key_id', value);
  }

  String get b2AppKey => _b2AppKey;
  set b2AppKey(String value) {
    _b2AppKey = value;
    _setSecure('b2_app_key', value);
  }

  String get b2Endpoint => _b2Endpoint;
  set b2Endpoint(String value) {
    _b2Endpoint = value;
    _setSecure('b2_endpoint', value);
  }

  String get b2BucketName => _b2BucketName;
  set b2BucketName(String value) {
    _b2BucketName = value;
    _setSecure('b2_bucket_name', value);
  }
}
