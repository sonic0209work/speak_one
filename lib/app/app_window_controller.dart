import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

enum WindowView { none, settings, explanation, history }

class AppWindowController extends ChangeNotifier {
  WindowView _view = WindowView.none;
  String _original = '';
  String _translation = '';
  String _explanation = '';
  bool _isTranslating = false;
  bool _isAiThinking = false;
  bool _isExplanationError = false;
  int _explanationGeneration = 0;
  int? _currentHistoryId;
  bool _isBookmarked = false;
  // Set when the panel is anchored near the cursor.
  // repositionForSize uses these to keep the panel pinned to the cursor edge.
  bool _anchoredNearSelection = false;
  bool _anchorAboveCursor = false; // true → bottom of panel tracks cursor
  double _anchorX = 0.0;
  double _anchorCursorY = 0.0;

  /// Set by TrayController to handle language-switch retranslation requests.
  Future<void> Function(String targetLang)? onRetranslateRequested;

  static const _explanationSize = Size(420, 80);

  WindowView get view => _view;
  String get original => _original;
  String get translation => _translation;
  String get explanation => _explanation;
  bool get isTranslating => _isTranslating;
  bool get isAiThinking => _isAiThinking;
  bool get isExplanationError => _isExplanationError;
  int get explanationGeneration => _explanationGeneration;
  int? get currentHistoryId => _currentHistoryId;
  bool get isBookmarked => _isBookmarked;

  String _captureStatus = '';
  String get captureStatus => _captureStatus;

  // Opens the window immediately with just the original text.
  Future<void> showOriginal(String original, {double? cursorX, double? cursorY}) async {
    if (_view == WindowView.settings) return;
    _original = original;
    _translation = '';
    _explanation = '';
    _isTranslating = true;
    _isAiThinking = false;
    _isExplanationError = false;
    _currentHistoryId = null;
    _isBookmarked = false;
    _captureStatus = '';
    _view = WindowView.explanation;
    _explanationGeneration++;
    _anchoredNearSelection = false;
    _anchorAboveCursor = false;
    _anchorX = 0;
    _anchorCursorY = 0;
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

  // Called with each streamed token delta; switches from "thinking" to text on first chunk.
  void streamExplanationChunk(String fullTextSoFar) {
    if (_view != WindowView.explanation) return;
    _explanation = fullTextSoFar;
    _isAiThinking = false;
    _isExplanationError = false;
    notifyListeners();
  }

  // Called when AI explanation is fully received (or failed with empty string).
  Future<void> updateExplanation(String explanation) async {
    if (_view != WindowView.explanation) return;
    _explanation = explanation;
    _isAiThinking = false;
    _isExplanationError = false;
    notifyListeners();
  }

  // Called when AI fails to reach Ollama; shows a user-visible hint.
  void setExplanationError(String message) {
    if (_view != WindowView.explanation) return;
    _explanation = message;
    _isAiThinking = false;
    _isExplanationError = true;
    notifyListeners();
  }

  Future<void> showCapturing() async {
    if (_view == WindowView.settings) return;
    _captureStatus = 'Capturing…';
    _view = WindowView.explanation;
    _original = '';
    _translation = '';
    _explanation = '';
    _isTranslating = false;
    _isAiThinking = false;
    _isExplanationError = false;
    _currentHistoryId = null;
    _isBookmarked = false;
    _explanationGeneration++;
    _anchoredNearSelection = false;
    notifyListeners();
    await windowManager.setMinimumSize(_explanationSize);
    await windowManager.setSize(_explanationSize);
    await _positionBottomRight(_explanationSize);
    await windowManager.show();
  }

  void setCaptureStatus(String status) {
    _captureStatus = status;
    notifyListeners();
  }

  void clearCaptureStatus() {
    _captureStatus = '';
  }

  void setHistoryEntry(int id, {required bool bookmarked}) {
    _currentHistoryId = id;
    _isBookmarked = bookmarked;
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
  Future<void> repositionForSize(double windowH) async {
    if (!_anchoredNearSelection) {
      await _positionBottomRight(Size(_explanationSize.width, windowH));
      return;
    }
    if (_anchorAboveCursor) {
      // Keep the bottom of the panel just above the cursor as it grows.
      const gap = 12.0;
      final y = (_anchorCursorY - gap - windowH).clamp(0.0, double.infinity);
      await windowManager.setPosition(Offset(_anchorX, y));
    }
    // Anchored below: grows downward naturally — no repositioning needed.
  }

  Future<void> showSettings() async {
    _view = WindowView.settings;
    notifyListeners();
    await windowManager.show();
    await windowManager.focus();
    // SettingsPage._resizeToContent() handles sizing and centering via postFrameCallback.
  }

  static const _historySize = Size(420, 560);

  Future<void> showHistory() async {
    _view = WindowView.history;
    notifyListeners();
    await windowManager.setMinimumSize(_historySize);
    await windowManager.setSize(_historySize);
    await windowManager.setAlignment(Alignment.center);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideWindow() async {
    _view = WindowView.none;
    _isTranslating = false;
    _isAiThinking = false;
    _anchoredNearSelection = false;
    _anchorAboveCursor = false;
    _anchorX = 0;
    _anchorCursorY = 0;
    notifyListeners();
    // Clear minimum-size constraint while the window is still mapped —
    // gtk_widget_set_size_request on a visible window is guaranteed effective.
    await windowManager.setMinimumSize(const Size(1, 1));
    await windowManager.hide();
  }

  // Positions the panel near the cursor, flipping above when space is tight.
  Future<void> _positionNearCursor(double cursorX, double cursorY) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final screen = display.size;
      const gap = 12.0;
      const pad = 12.0;
      const taskbar = 48.0;
      final panelW = _explanationSize.width;
      final panelH = _explanationSize.height; // initial height (80px)
      final x = cursorX.clamp(pad, screen.width - panelW - pad);
      final spaceBelow = screen.height - taskbar - cursorY - gap;
      final spaceAbove = cursorY - gap;

      if (spaceBelow >= panelH) {
        // Enough room below — anchor below, panel grows downward.
        await windowManager.setPosition(Offset(x, cursorY + gap));
        _anchoredNearSelection = true;
        _anchorAboveCursor = false;
        _anchorX = x;
        _anchorCursorY = cursorY;
        return;
      }

      if (spaceAbove >= panelH) {
        // Not enough below — flip above cursor, panel grows upward.
        await windowManager.setPosition(Offset(x, cursorY - gap - panelH));
        _anchoredNearSelection = true;
        _anchorAboveCursor = true;
        _anchorX = x;
        _anchorCursorY = cursorY;
        return;
      }
    } catch (_) {}

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
