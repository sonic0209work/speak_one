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
    _appWindowController.onRetranslateRequested = _retranslateWith;
    _appWindowController.addListener(_onWindowChanged);
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

    // Open window immediately, then fill translation + AI in background.
    await _appWindowController.showOriginal(event.text, cursorX: event.cursorX, cursorY: event.cursorY);
    _translateAndUpdate(event.text, generation);

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

    // Cursor is now at the corner of the captured region — use it to anchor the panel.
    final cursorPos = await AccessibilityPlugin.queryCursorPosition();
    if (_generation != generation) return;

    await _trayIconService.setSpeaking();
    await _appWindowController.showOriginal(
      text,
      cursorX: cursorPos?.$1,
      cursorY: cursorPos?.$2,
    );
    _translateAndUpdate(text, generation);

    final ttsResult = await _ttsRepository.speak(text);
    if (_generation != generation) return;
    if (ttsResult is Success) {
      await _trayIconService.setIdle();
    } else {
      await _trayIconService.setError();
    }
  }

  void _onWindowChanged() {
    if (_appWindowController.view != WindowView.none) return;
    ++_generation;
    _aiCancelToken?.cancel();
    _aiCancelToken = null;
    _trayIconService.stopThinking();
    _trayIconService.setIdle();
  }

  // Fetches translation then AI explanation, updating the already-visible window.
  Future<void> _translateAndUpdate(String text, int generation) async {
    final translateResult = await _translateService.translate(text);
    if (_generation != generation) return;
    if (translateResult is! Success<String>) return;

    final aiEnabled = GetIt.I<SettingsService>().aiEnabled;
    await _appWindowController.updateTranslation(
      translateResult.value,
      aiPending: aiEnabled,
    );

    if (!aiEnabled) {
      _notificationService.playDing();
      return;
    }

    _aiCancelToken?.cancel();
    final token = _aiCancelToken = CancelToken();
    _trayIconService.startThinking();
    final aiBuffer = StringBuffer();
    try {
      await for (final chunk in _ollamaService.explainStream(text, cancelToken: token)) {
        if (_generation != generation) return;
        aiBuffer.write(chunk);
        _appWindowController.streamExplanationChunk(aiBuffer.toString());
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
    }
    if (_generation != generation) return;
    _aiCancelToken = null;
    await _trayIconService.stopThinking();
    if (aiBuffer.isEmpty) await _appWindowController.updateExplanation('');
    _notificationService.playDing();
  }

  // Retranslates the current original text with a specific target language.
  Future<void> _retranslateWith(String targetLang) async {
    final generation = _generation;
    final text = _appWindowController.original;
    if (text.isEmpty) return;

    final result = await _translateService.translate(text, targetLang: targetLang);
    if (_generation != generation) return;

    await _appWindowController.updateTranslation(
      result is Success<String> ? result.value : '',
      aiPending: false,
    );
    _notificationService.playDing();
  }

  void dispose() {
    _atSpiSubscription.cancel();
    _hotkeySubscription.cancel();
    _appWindowController.removeListener(_onWindowChanged);
  }
}
