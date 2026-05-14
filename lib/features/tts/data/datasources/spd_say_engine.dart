import 'dart:io';

import 'tts_engine.dart';

class SpdSayEngine implements TtsEngine {
  Process? _process;
  void Function(dynamic)? _errorHandler;

  @override
  Future<dynamic> speak(String text) async {
    _process = await Process.start('spd-say', [text]);
    final exitCode = await _process!.exitCode;
    _process = null;
    if (exitCode != 0) {
      _errorHandler?.call('spd-say exited with code $exitCode');
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
