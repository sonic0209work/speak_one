import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../../../core/types/result.dart';

class OcrDatasource {
  // Maps speak_one lang codes → tesseract language codes.
  // English is always appended (+eng) to handle mixed-language text.
  static const _langMap = {
    'zh-TW': 'chi_tra+eng',
    'zh-CN': 'chi_sim+eng',
    'ja': 'jpn+eng',
    'ko': 'kor+eng',
    'fr': 'fra+eng',
    'de': 'deu+eng',
    'es': 'spa+eng',
    'en': 'eng',
    'auto': 'chi_tra+chi_sim+eng',
  };

  Future<Result<String>> extract(String imagePath, {String sourceLang = 'auto'}) async {
    final which = await Process.run('which', ['tesseract']);
    if (which.exitCode != 0) {
      return const Failure(
        OcrCaptureException('Install tesseract: sudo apt install tesseract-ocr'),
      );
    }

    final tessLang = _langMap[sourceLang];
    final result = await _runTesseract(imagePath, tessLang);
    if (result.exitCode == 0) {
      return Success((result.stdout as String).trim());
    }

    // Language pack missing or other error — retry with eng-only fallback.
    if (tessLang != null && tessLang != 'eng') {
      final retry = await _runTesseract(imagePath, 'eng');
      if (retry.exitCode == 0) {
        return Success((retry.stdout as String).trim());
      }
    }

    return Failure(OcrCaptureException('OCR failed: ${result.stderr}'));
  }

  Future<ProcessResult> _runTesseract(String imagePath, String? lang) {
    return Process.run('tesseract', [
      imagePath,
      'stdout',
      if (lang != null) ...['-l', lang],
    ]);
  }
}
