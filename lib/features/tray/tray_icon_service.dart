import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

class TrayIconService with TrayListener {
  static const _idle = 'audio-volume-medium';
  static const _speaking = 'audio-volume-high';
  static const _error = 'audio-volume-muted';

  Future<void> init() async {
    trayManager.addListener(this);
    await trayManager.setIcon(_idle);
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'exit', label: 'Exit'),
    ]));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'exit') exit(0);
  }

  Future<void> setIdle() => trayManager.setIcon(_idle);
  Future<void> setSpeaking() => trayManager.setIcon(_speaking);
  Future<void> setError() => trayManager.setIcon(_error);
}
