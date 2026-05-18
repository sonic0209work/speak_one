import 'dart:io';

import '../../../core/errors/app_exception.dart';
import '../../../core/types/result.dart';

class ScreenshotDatasource {
  Future<Result<String>> capture(String destPath) async {
    final session = Platform.environment['XDG_SESSION_TYPE'] ?? '';
    if (session.toLowerCase() == 'wayland') {
      return const Failure(OcrCaptureException('OCR capture requires X11'));
    }

    final which = await Process.run('which', ['scrot']);
    if (which.exitCode != 0) {
      return const Failure(
        OcrCaptureException('Install scrot: sudo apt install scrot'),
      );
    }

    final result = await Process.run('scrot', ['-s', destPath]);
    if (result.exitCode != 0) {
      return const Failure(OcrCaptureException('cancelled', isSilent: true));
    }

    return Success(destPath);
  }
}
