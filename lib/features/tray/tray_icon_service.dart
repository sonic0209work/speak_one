import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';

class TrayIconService with TrayListener {
  static const _idle = 'speak_one_idle';
  static const _speaking = 'speak_one_speaking';
  static const _error = 'speak_one_error';

  static const _thinkingFrames = [
    'speak_one_thinking_0',
    'speak_one_thinking_1',
    'speak_one_thinking_2',
    'speak_one_thinking_3',
  ];

  static const _allIcons = [
    _idle, _speaking, _error,
    ..._thinkingFrames,
  ];

  VoidCallback? onSettingsRequested;

  String _logicalIcon = _idle;
  int _frameIndex = 0;
  Timer? _thinkingTimer;

  Future<void> init() async {
    await _installIcons();
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
    if (_thinkingTimer != null) return;
    _frameIndex = 0;
    _thinkingTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => trayManager.setIcon(
        _thinkingFrames[_frameIndex++ % _thinkingFrames.length],
      ),
    );
  }

  Future<void> stopThinking() async {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
    await trayManager.setIcon(_logicalIcon);
  }

  Future<void> _setLogical(String icon) async {
    _logicalIcon = icon;
    if (_thinkingTimer == null) await trayManager.setIcon(icon);
  }

  Future<void> _installIcons() async {
    final home = Platform.environment['HOME'];
    if (home == null) return;

    final dir = Directory('$home/.local/share/icons/hicolor/scalable/apps');
    await dir.create(recursive: true);

    var anyNew = false;
    for (final name in _allIcons) {
      final dest = File('${dir.path}/$name.svg');
      if (!await dest.exists()) {
        final data = await rootBundle.load('assets/icons/$name.svg');
        await dest.writeAsBytes(data.buffer.asUint8List());
        anyNew = true;
      }
    }

    // Only refresh cache when icons were newly installed — running this on
    // every startup causes a GTK icon-theme reload race that crashes XFCE's
    // systray plugin with an integer-overflow allocation error.
    if (anyNew) {
      await Process.run('gtk-update-icon-cache', [
        '--force', '--ignore-theme-index',
        '$home/.local/share/icons/hicolor/',
      ]);
    }
  }
}
