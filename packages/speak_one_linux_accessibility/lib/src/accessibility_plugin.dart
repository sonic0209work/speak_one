import 'dart:async';

import 'atspi_bindings.dart' as atspi;
import 'display_server_detector.dart';
import 'text_selection_event.dart';
import 'x11_bindings.dart' as x11;

/// Unified entry point for system-wide text selection detection on Linux.
///
/// Automatically selects the AT-SPI2 path (Wayland/GNOME) or the XCB path (X11)
/// based on the current display server environment.
abstract final class AccessibilityPlugin {
  /// Returns a broadcast stream of [TextSelectionEvent].
  ///
  /// Throws [UnsupportedError] if no supported display server is detected.
  static Stream<TextSelectionEvent> listen() {
    return switch (DisplayServerDetector.detect()) {
      DisplayServer.wayland => atspi.listenAtspi(),
      DisplayServer.x11 => x11.listenX11(),
      DisplayServer.unknown => Stream.error(
          UnsupportedError('No supported display server detected. '
              'Set WAYLAND_DISPLAY (Wayland) or DISPLAY (X11).'),
        ),
    };
  }

  /// Returns the current mouse cursor position on X11.
  /// Returns null on Wayland (pointer position not directly accessible).
  static Future<(double, double)?> queryCursorPosition() async {
    if (DisplayServerDetector.detect() == DisplayServer.x11) {
      return x11.queryCursorPositionX11();
    }
    return null;
  }

  /// Returns the currently detected [DisplayServer].
  static DisplayServer get currentDisplayServer =>
      DisplayServerDetector.detect();
}
