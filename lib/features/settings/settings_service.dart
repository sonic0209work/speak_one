import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keySourceLang = 'source_lang';
  static const _keyTargetLang = 'target_lang';

  static const _defaultSource = 'auto';
  static const _defaultTarget = 'zh-TW';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get sourceLang => _prefs?.getString(_keySourceLang) ?? _defaultSource;
  String get targetLang => _prefs?.getString(_keyTargetLang) ?? _defaultTarget;

  Future<void> setSourceLang(String lang) async =>
      _prefs?.setString(_keySourceLang, lang);

  Future<void> setTargetLang(String lang) async =>
      _prefs?.setString(_keyTargetLang, lang);
}
