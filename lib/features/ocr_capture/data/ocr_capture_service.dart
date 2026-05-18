import 'dart:io';

import 'package:get_it/get_it.dart';

import '../../../core/types/result.dart';
import '../../settings/settings_service.dart';
import 'ocr_datasource.dart';
import 'screenshot_datasource.dart';

class OcrCaptureService {
  OcrCaptureService({
    ScreenshotDatasource? screenshot,
    OcrDatasource? ocr,
  })  : _screenshot = screenshot ?? ScreenshotDatasource(),
        _ocr = ocr ?? OcrDatasource();

  final ScreenshotDatasource _screenshot;
  final OcrDatasource _ocr;

  Future<Result<String>> capture() async {
    final tmpPath =
        '/tmp/speak_one_ocr_${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      final screenshotResult = await _screenshot.capture(tmpPath);
      if (screenshotResult is Failure) return screenshotResult;

      final sourceLang = GetIt.I<SettingsService>().sourceLang;
      return await _ocr.extract(tmpPath, sourceLang: sourceLang);
    } finally {
      final file = File(tmpPath);
      if (await file.exists()) await file.delete();
    }
  }
}
