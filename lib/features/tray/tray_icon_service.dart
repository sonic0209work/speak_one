import 'package:tray_manager/tray_manager.dart';

class TrayIconService {
  // XDG icon theme names — AppIndicator resolves these from the system theme,
  // avoiding the file-path caching issue in app_indicator_set_icon_full.
  static const _idle = 'audio-volume-medium';
  static const _speaking = 'audio-volume-high';
  static const _error = 'audio-volume-muted';

  Future<void> init() => trayManager.setIcon(_idle);

  Future<void> setIdle() => trayManager.setIcon(_idle);
  Future<void> setSpeaking() => trayManager.setIcon(_speaking);
  Future<void> setError() => trayManager.setIcon(_error);
}
