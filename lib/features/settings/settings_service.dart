import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keySourceLang = 'source_lang';
  static const _keyTargetLang = 'target_lang';
  static const _keyAiEnabled = 'ai_enabled';
  static const _keyOllamaUrl = 'ollama_url';
  static const _keyOllamaModel = 'ollama_model';

  static const _defaultSource = 'auto';
  static const _defaultTarget = 'zh-TW';
  static const _defaultOllamaUrl = 'http://localhost:11434';
  static const _defaultOllamaModel = 'qwen3:1.7b';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get sourceLang => _prefs?.getString(_keySourceLang) ?? _defaultSource;
  String get targetLang => _prefs?.getString(_keyTargetLang) ?? _defaultTarget;
  bool get aiEnabled => _prefs?.getBool(_keyAiEnabled) ?? false;
  String get ollamaUrl => _prefs?.getString(_keyOllamaUrl) ?? _defaultOllamaUrl;
  String get ollamaModel => _prefs?.getString(_keyOllamaModel) ?? _defaultOllamaModel;

  Future<void> setSourceLang(String v) async => _prefs?.setString(_keySourceLang, v);
  Future<void> setTargetLang(String v) async => _prefs?.setString(_keyTargetLang, v);
  Future<void> setAiEnabled(bool v) async => _prefs?.setBool(_keyAiEnabled, v);
  Future<void> setOllamaUrl(String v) async => _prefs?.setString(_keyOllamaUrl, v);
  Future<void> setOllamaModel(String v) async => _prefs?.setString(_keyOllamaModel, v);
}
