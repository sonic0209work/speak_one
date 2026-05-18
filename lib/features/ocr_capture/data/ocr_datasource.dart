import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../../../core/types/result.dart';

class OcrDatasource {
  Future<Result<String>> extract(String imagePath) async {
    final which = await Process.run('which', ['tesseract']);
    if (which.exitCode != 0) {
      return const Failure(
        OcrCaptureException('Install tesseract: sudo apt install tesseract-ocr'),
      );
    }

    final result = await Process.run('tesseract', [imagePath, 'stdout', '-']);
    if (result.exitCode != 0) {
      return Failure(
        OcrCaptureException('OCR failed: ${result.stderr}'),
      );
    }

    return Success((result.stdout as String).trim());
  }
}
