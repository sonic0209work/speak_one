import 'dart:async';

import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

import '../../core/services/isolate_service.dart';
import '../../core/types/result.dart';
import '../../features/detection/domain/services/selection_filter_service.dart';
import '../../features/tts/domain/tts_repository.dart';
import 'tray_icon_service.dart';

class TrayController {
  TrayController({
    required IsolateService isolateService,
    required TrayIconService trayIconService,
    required TtsRepository ttsRepository,
  })  : _trayIconService = trayIconService,
        _ttsRepository = ttsRepository {
    final filter = SelectionFilterService();
    _subscription = filter.filter(isolateService.events).listen(_onSelection);
  }

  final TrayIconService _trayIconService;
  final TtsRepository _ttsRepository;
  late final StreamSubscription<TextSelectionEvent> _subscription;
  int _generation = 0;

  Future<void> _onSelection(TextSelectionEvent event) async {
    final generation = ++_generation;
    await _trayIconService.setSpeaking();
    await _ttsRepository.stop();
    final result = await _ttsRepository.speak(event.text);
    if (_generation != generation) return; // superseded by a newer selection
    if (result is Success) {
      await _trayIconService.setIdle();
    } else {
      await _trayIconService.setError();
    }
  }

  void dispose() => _subscription.cancel();
}
