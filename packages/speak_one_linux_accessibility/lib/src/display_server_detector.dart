import 'dart:io' show Platform;

enum DisplayServer { wayland, x11, unknown }

abstract final class DisplayServerDetector {
  static DisplayServer detect() {
    final wayland = Platform.environment['WAYLAND_DISPLAY'];
    if (wayland != null && wayland.isNotEmpty) return DisplayServer.wayland;

    final display = Platform.environment['DISPLAY'];
    if (display != null && display.isNotEmpty) return DisplayServer.x11;

    return DisplayServer.unknown;
  }
}
