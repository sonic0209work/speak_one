import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

enum WindowView { none, settings, explanation }

class AppWindowController extends ChangeNotifier {
  WindowView _view = WindowView.none;
  String _original = '';
  String _translation = '';
  String _explanation = '';
  bool _isTranslating = false;
  bool _isAiThinking = false;
  int _explanationGeneration = 0;

  static const _settingsSize = Size(420, 400);
  static const _explanationSize = Size(420, 80);

  WindowView get view => _view;
  String get original => _original;
  String get translation => _translation;
  String get explanation => _explanation;
  bool get isTranslating => _isTranslating;
  bool get isAiThinking => _isAiThinking;
  int get explanationGeneration => _explanationGeneration;

  // Opens the window immediately with just the original text.
  Future<void> showOriginal(String original) async {
    if (_view == WindowView.settings) return;
    _original = original;
    _translation = '';
    _explanation = '';
    _isTranslating = true;
    _isAiThinking = false;
    _view = WindowView.explanation;
    _explanationGeneration++;
    notifyListeners();

    await windowManager.setMinimumSize(_explanationSize);
    await windowManager.setSize(_explanationSize);
    await _positionBottomRight(_explanationSize);
    await windowManager.show();
  }

  // Called when translation is ready; window is already visible.
  Future<void> updateTranslation(String translation, {bool aiPending = false}) async {
    if (_view != WindowView.explanation) return;
    _translation = translation;
    _isTranslating = false;
    _isAiThinking = aiPending;
    notifyListeners();
  }

  // Called when AI explanation is ready.
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
    _isTranslating = false;
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
