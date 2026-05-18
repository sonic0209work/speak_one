import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../../../core/types/result.dart';

class OcrDatasource {
  // Maps speak_one lang codes → tesseract language codes.
  static const _langMap = {
    'zh-TW': 'chi_tra',
    'zh-CN': 'chi_sim',
    'ja': 'jpn',
    'ko': 'kor',
    'fr': 'fra',
    'de': 'deu',
    'es': 'spa',
    'en': 'eng',
  };

  Future<Result<String>> extract(String imagePath, {String sourceLang = 'auto'}) async {
    final which = await Process.run('which', ['tesseract']);
    if (which.exitCode != 0) {
      return const Failure(
        OcrCaptureException('Install tesseract: sudo apt install tesseract-ocr'),
      );
    }

    final tessLang = _langMap[sourceLang];
    final args = [
      imagePath,
      'stdout',
      if (tessLang != null) ...['-l', tessLang],
    ];

    final result = await Process.run('tesseract', args);
    if (result.exitCode != 0) {
      return Failure(
        OcrCaptureException('OCR failed: ${result.stderr}'),
      );
    }

    return Success((result.stdout as String).trim());
  }
}
