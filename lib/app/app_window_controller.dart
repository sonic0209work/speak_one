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
  // True when the window was successfully anchored below a text selection.
  // While true, repositionForSize skips repositioning so the window grows
  // downward in-place rather than jumping to bottom-right on every resize.
  bool _anchoredNearSelection = false;

  /// Set by TrayController to handle language-switch retranslation requests.
  Future<void> Function(String targetLang)? onRetranslateRequested;

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
  Future<void> showOriginal(String original, {double? cursorX, double? cursorY}) async {
    if (_view == WindowView.settings) return;
    _original = original;
    _translation = '';
    _explanation = '';
    _isTranslating = true;
    _isAiThinking = false;
    _view = WindowView.explanation;
    _explanationGeneration++;
    _anchoredNearSelection = false;
    notifyListeners();

    await windowManager.setMinimumSize(_explanationSize);
    await windowManager.setSize(_explanationSize);

    if (cursorX != null && cursorY != null) {
      await _positionNearCursor(cursorX, cursorY);
    } else {
      await _positionBottomRight(_explanationSize);
    }
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

  /// Called from the panel's language-switch bar; TrayController provides the impl.
  void retranslate(String targetLang) {
    if (_view != WindowView.explanation) return;
    _isTranslating = true;
    _isAiThinking = false;
    _explanation = '';
    notifyListeners();
    onRetranslateRequested?.call(targetLang);
  }

  /// Called by ExplanationPage on every content resize.
  /// If the window was anchored below the selection it grows downward in-place;
  /// otherwise it is repositioned to the bottom-right corner.
  Future<void> repositionForSize(double windowH) async {
    if (_anchoredNearSelection) return;
    await _positionBottomRight(Size(_explanationSize.width, windowH));
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
    _anchoredNearSelection = false;
    notifyListeners();
    await windowManager.hide();
  }

  // Positions the panel just below the cursor position.
  // Falls back to bottom-right if there is not enough vertical space.
  Future<void> _positionNearCursor(double cursorX, double cursorY) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final screen = display.size;
      const gap = 12.0;
      const pad = 12.0;
      const taskbar = 48.0;
      final panelW = _explanationSize.width;
      final panelH = _explanationSize.height; // initial height (80px)

      final belowY = cursorY + gap;

      // Anchor below cursor as long as the initial panel height fits.
      // The panel may grow past the screen edge later; that is acceptable.
      if (belowY + panelH + pad <= screen.height - taskbar) {
        final x = cursorX.clamp(pad, screen.width - panelW - pad);
        await windowManager.setPosition(Offset(x, belowY));
        _anchoredNearSelection = true;
        return;
      }
    } catch (_) {}

    // Fallback: standard bottom-right
    await _positionBottomRight(_explanationSize);
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
