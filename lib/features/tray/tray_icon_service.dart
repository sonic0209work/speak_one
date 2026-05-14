import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

class TrayIconService with TrayListener {
  static const _idle = 'audio-volume-medium';
  static const _speaking = 'audio-volume-high';
  static const _error = 'audio-volume-muted';

  // Thinking animation: pulse muted → medium → high → medium → …
  static const _thinkingFrames = [
    'audio-volume-muted',
    'audio-volume-medium',
    'audio-volume-high',
    'audio-volume-medium',
  ];

  VoidCallback? onSettingsRequested;

  String _logicalIcon = _idle;
  int _thinkingCount = 0;
  int _frameIndex = 0;
  Timer? _thinkingTimer;

  Future<void> init() async {
    trayManager.addListener(this);
    await trayManager.setIcon(_idle);
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'settings', label: 'Settings'),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: 'Exit'),
    ]));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'settings':
        onSettingsRequested?.call();
      case 'exit':
        exit(0);
    }
  }

  Future<void> setIdle() => _setLogical(_idle);
  Future<void> setSpeaking() => _setLogical(_speaking);
  Future<void> setError() => _setLogical(_error);

  void startThinking() {
    _thinkingCount++;
    if (_thinkingCount == 1) {
      _frameIndex = 0;
      _thinkingTimer = Timer.periodic(
        const Duration(milliseconds: 300),
        (_) => trayManager.setIcon(
          _thinkingFrames[_frameIndex++ % _thinkingFrames.length],
        ),
      );
    }
  }

  Future<void> stopThinking() async {
    _thinkingCount = (_thinkingCount - 1).clamp(0, 999);
    if (_thinkingCount == 0) {
      _thinkingTimer?.cancel();
      _thinkingTimer = null;
      await trayManager.setIcon(_logicalIcon);
    }
  }

  Future<void> _setLogical(String icon) async {
    _logicalIcon = icon;
    if (_thinkingCount == 0) await trayManager.setIcon(icon);
  }
}
