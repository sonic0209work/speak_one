import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

enum WindowView { none, settings, explanation }

class AppWindowController extends ChangeNotifier {
  WindowView _view = WindowView.none;
  String _original = '';
  String _translation = '';
  String _explanation = '';
  bool _isAiThinking = false;
  int _explanationGeneration = 0;

  static const _settingsSize = Size(420, 400);
  static const _explanationSize = Size(420, 240);

  WindowView get view => _view;
  String get original => _original;
  String get translation => _translation;
  String get explanation => _explanation;
  bool get isAiThinking => _isAiThinking;
  int get explanationGeneration => _explanationGeneration;

  // Show window with translation immediately; set isAiThinking if AI will follow.
  Future<void> showTranslation(
    String original,
    String translation, {
    bool aiPending = true,
  }) async {
    if (_view == WindowView.settings) return;
    _original = original;
    _translation = translation;
    _explanation = '';
    _isAiThinking = aiPending;
    _view = WindowView.explanation;
    _explanationGeneration++;
    notifyListeners();

    await windowManager.setMinimumSize(_explanationSize);
    await windowManager.setSize(_explanationSize);
    await _positionBottomRight(_explanationSize);
    await windowManager.show();
  }

  // Called when AI explanation arrives; updates the already-visible window.
  Future<void> updateExplanation(String explanation) async {
    if (_view != WindowView.explanation) return;
    _explanation = explanation;
    _isAiThinking = false;
    notifyListeners();
  }

  Future<void> showSettings() async {
    _view = WindowView.settings;
    notifyListeners();
    await windowManager.setMinimumSize(_settingsSize);
    await windowManager.setSize(_settingsSize);
    await windowManager.setAlignment(Alignment.center);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideWindow() async {
    _view = WindowView.none;
    _isAiThinking = false;
    notifyListeners();
    await windowManager.hide();
  }

  Future<void> _positionBottomRight(Size windowSize) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final screen = display.size;
      const margin = 16.0;
      const taskbar = 48.0;
      await windowManager.setPosition(Offset(
        screen.width - windowSize.width - margin,
        screen.height - windowSize.height - margin - taskbar,
      ));
    } catch (_) {
      await windowManager.setAlignment(Alignment.bottomRight);
    }
  }
}
