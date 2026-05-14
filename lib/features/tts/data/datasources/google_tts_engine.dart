import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../../../features/settings/settings_service.dart';
import 'tts_engine.dart';

class GoogleTtsEngine implements TtsEngine {
  Process? _process;
  void Function(dynamic)? _errorHandler;

  static final _cjkRegex = RegExp(r'[一-鿿㐀-䶿]');

  String _langFor(String text) {
    final settings = GetIt.I<SettingsService>();
    final src = settings.sourceLang;
    if (src != 'auto') return src;
    return _cjkRegex.hasMatch(text) ? 'zh-TW' : 'en';
  }

  String _buildUrl(String text) {
    // Google TTS has ~200-char limit; truncate to avoid silent failure.
    final q = text.length > 200 ? text.substring(0, 200) : text;
    final encoded = Uri.encodeComponent(q);
    final lang = _langFor(text);
    return 'https://translate.googleapis.com/translate_tts'
        '?ie=UTF-8&q=$encoded&tl=$lang&client=gtx';
  }

  @override
  Future<dynamic> speak(String text) async {
    _process = await Process.start('ffplay', [
      '-nodisp', '-autoexit', '-loglevel', 'quiet',
      _buildUrl(text),
    ]);
    final exitCode = await _process!.exitCode;
    _process = null;
    if (exitCode != 0) {
      _errorHandler?.call('ffplay exited with code $exitCode');
      return exitCode;
    }
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
  }

  @override
  void setErrorHandler(void Function(dynamic) handler) {
    _errorHandler = handler;
  }
}
