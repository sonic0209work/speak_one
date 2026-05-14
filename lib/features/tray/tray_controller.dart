import 'dart:async';

import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

import '../../core/services/isolate_service.dart';
import '../../core/types/result.dart';
import '../../features/detection/domain/services/selection_filter_service.dart';
import '../../features/notification/notification_service.dart';
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
  })  : _trayIconService = trayIconService,
        _ttsRepository = ttsRepository,
        _translateService = translateService,
        _notificationService = notificationService {
    final filter = SelectionFilterService();
    _subscription = filter.filter(isolateService.events).listen(_onSelection);
  }

  final TrayIconService _trayIconService;
  final TtsRepository _ttsRepository;
  final TranslateService _translateService;
  final NotificationService _notificationService;
  late final StreamSubscription<TextSelectionEvent> _subscription;
  int _generation = 0;

  Future<void> _onSelection(TextSelectionEvent event) async {
    final generation = ++_generation;
    await _trayIconService.setSpeaking();
    await _ttsRepository.stop();

    // Translation fires in parallel — notification appears as soon as it resolves.
    _translateAndNotify(event.text, generation);

    final result = await _ttsRepository.speak(event.text);
    if (_generation != generation) return;
    if (result is Success) {
      await _trayIconService.setIdle();
    } else {
      await _trayIconService.setError();
    }
  }

  Future<void> _translateAndNotify(String text, int generation) async {
    final result = await _translateService.translate(text);
    if (_generation != generation) return;
    if (result is Success<String>) {
      await _notificationService.show(text, result.value);
    }
  }

  void dispose() => _subscription.cancel();
}
