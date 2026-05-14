import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

enum WindowView { none, settings, explanation }

class AppWindowController extends ChangeNotifier {
  WindowView _view = WindowView.none;
  String _original = '';
  String _explanation = '';
  int _explanationGeneration = 0;

  WindowView get view => _view;
  String get original => _original;
  String get explanation => _explanation;
  int get explanationGeneration => _explanationGeneration;

  static const _settingsSize = Size(420, 520);
  static const _explanationSize = Size(420, 340);

  Future<void> showSettings() async {
    _view = WindowView.settings;
    notifyListeners();
    await windowManager.setMinimumSize(_settingsSize);
    await windowManager.setSize(_settingsSize);
    await windowManager.setAlignment(Alignment.center);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> showExplanation(String original, String explanation) async {
    // Don't cover settings if it's open.
    if (_view == WindowView.settings) return;

    _original = original;
    _explanation = explanation;
    _view = WindowView.explanation;
    _explanationGeneration++;
    notifyListeners();

    await windowManager.setMinimumSize(_explanationSize);
    await windowManager.setSize(_explanationSize);
    await _positionBottomRight(_explanationSize);
    await windowManager.show();
  }

  Future<void> hideWindow() async {
    _view = WindowView.none;
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
