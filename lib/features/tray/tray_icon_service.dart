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
  String _cacheDir = '';

  Future<void> init() async {
    _cacheDir = await _installIcons();
    trayManager.addListener(this);
    await trayManager.setIcon(_path(_idle));
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

  String _path(String name) => '$_cacheDir/$name.png';

  Future<void> setIdle() => _setLogical(_idle);
  Future<void> setSpeaking() => _setLogical(_speaking);
  Future<void> setError() => _setLogical(_error);

  void startThinking() {
    if (_thinkingTimer != null) return;
    _frameIndex = 0;
    _thinkingTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => trayManager.setIcon(
        _path(_thinkingFrames[_frameIndex++ % _thinkingFrames.length]),
      ),
    );
  }

  Future<void> stopThinking() async {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
    await trayManager.setIcon(_path(_logicalIcon));
  }

  Future<void> _setLogical(String icon) async {
    _logicalIcon = icon;
    if (_thinkingTimer == null) await trayManager.setIcon(_path(icon));
  }

  // Installs PNG tray icons to ~/.cache/speak_one/icons/ and returns that path.
  // Uses the cache dir (not the icon theme) so no gtk-update-icon-cache is needed.
  Future<String> _installIcons() async {
    final home = Platform.environment['HOME'] ?? '';
    final dir = Directory('$home/.cache/speak_one/icons');
    await dir.create(recursive: true);

    for (final name in _allIcons) {
      final dest = File('${dir.path}/$name.png');
      if (!await dest.exists()) {
        final data = await rootBundle.load('assets/icons/tray/$name.png');
        await dest.writeAsBytes(data.buffer.asUint8List());
      }
    }

    return dir.path;
  }
}
