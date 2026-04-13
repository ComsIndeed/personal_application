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

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load secure values into cache
    _geminiApiKey = await _secureStorage.read(key: 'gemini_api_key') ?? '';
    _deepSeekApiKey = await _secureStorage.read(key: 'deepseek_api_key') ?? '';
    _groqApiKey = await _secureStorage.read(key: 'groq_api_key') ?? '';
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
}
