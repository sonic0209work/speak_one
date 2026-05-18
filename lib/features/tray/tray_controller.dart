import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

import '../../app/app_window_controller.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/isolate_service.dart';
import '../../core/types/result.dart';
import '../../features/ai_explain/data/ollama_service.dart';
import '../../features/detection/domain/services/selection_filter_service.dart';
import '../../features/hotkey/data/hotkey_repository.dart';
import '../../features/notification/notification_service.dart';
import '../../features/ocr_capture/data/ocr_capture_service.dart';
import '../../features/settings/settings_service.dart';
import '../../features/translate/data/translate_service.dart';
import '../../features/tts/domain/tts_repository.dart';
import 'tray_icon_service.dart';

class TrayController {
  TrayController({
    required IsolateService isolateService,
    required TrayIconService trayIconService,
    required TtsRepository ttsRepository,
    required TranslateService translateService,
    required NotificationService notificationService,
    required OllamaService ollamaService,
    required AppWindowController appWindowController,
    required HotkeyRepository hotkeyRepository,
    required OcrCaptureService ocrCaptureService,
  })  : _trayIconService = trayIconService,
        _ttsRepository = ttsRepository,
        _translateService = translateService,
        _notificationService = notificationService,
        _ollamaService = ollamaService,
        _appWindowController = appWindowController,
        _ocrCaptureService = ocrCaptureService {
    final filter = SelectionFilterService();
    _atSpiSubscription = filter.filter(isolateService.events).listen(_onSelection);
    _hotkeySubscription = hotkeyRepository.activations.listen((_) => _handleCapture());
  }

  final TrayIconService _trayIconService;
  final TtsRepository _ttsRepository;
  final TranslateService _translateService;
  final NotificationService _notificationService;
  final OllamaService _ollamaService;
  final AppWindowController _appWindowController;
  final OcrCaptureService _ocrCaptureService;
  late final StreamSubscription<TextSelectionEvent> _atSpiSubscription;
  late final StreamSubscription<void> _hotkeySubscription;
  int _generation = 0;
  CancelToken? _aiCancelToken;

  Future<void> _onSelection(TextSelectionEvent event) async {
    final generation = ++_generation;
    await _trayIconService.setSpeaking();
    await _ttsRepository.stop();

    _translateThenShow(event.text, generation);

    final result = await _ttsRepository.speak(event.text);
    if (_generation != generation) return;
    if (result is Success) {
      await _trayIconService.setIdle();
    } else {
      await _trayIconService.setError();
    }
  }

  Future<void> _handleCapture() async {
    final generation = ++_generation;
    final result = await _ocrCaptureService.capture();
    if (_generation != generation) return;

    if (result is Failure<String>) {
      final err = result.error;
      if (err is OcrCaptureException && !err.isSilent) {
        await _notificationService.showMessage('Speak One', err.message);
      }
      return;
    }

    final text = (result as Success<String>).value;
    if (text.isEmpty) {
      await _notificationService.showMessage('Speak One', 'No text found in captured region');
      return;
    }

    await _trayIconService.setSpeaking();
    _translateThenShow(text, generation);

    final ttsResult = await _ttsRepository.speak(text);
    if (_generation != generation) return;
    if (ttsResult is Success) {
      await _trayIconService.setIdle();
    } else {
      await _trayIconService.setError();
    }
  }

  // Translates text, shows the window, then (if AI enabled) fetches explanation.
  Future<void> _translateThenShow(String text, int generation) async {
    final translateResult = await _translateService.translate(text);
    if (_generation != generation) return;
    if (translateResult is! Success<String>) return;

    final aiEnabled = GetIt.I<SettingsService>().aiEnabled;
    await _appWindowController.showTranslation(
      text,
      translateResult.value,
      aiPending: aiEnabled,
    );

    if (!aiEnabled) return;

    _aiCancelToken?.cancel();
    final token = _aiCancelToken = CancelToken();
    _trayIconService.startThinking();
    final aiResult = await _ollamaService.explain(text, cancelToken: token);
    if (_generation != generation) return;
    _aiCancelToken = null;
    await _trayIconService.stopThinking();
    if (aiResult is Success<String>) {
      await _appWindowController.updateExplanation(aiResult.value);
    } else {
      // AI failed — clear the thinking indicator so the window doesn't hang.
      await _appWindowController.updateExplanation('');
    }
  }

  void dispose() {
    _atSpiSubscription.cancel();
    _hotkeySubscription.cancel();
  }
}
