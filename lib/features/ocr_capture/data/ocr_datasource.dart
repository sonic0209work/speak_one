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
    'auto': 'chi_tra+chi_sim',
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
