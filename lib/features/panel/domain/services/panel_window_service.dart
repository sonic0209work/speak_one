import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';
import 'package:window_manager/window_manager.dart';

class PanelWindowService {
  Future<void> show(SelectionRect bounds) async {
    if (bounds.width > 0) {
      // Wayland: real bounding box — position panel just below the selection
      await windowManager.setPosition(
        Offset(bounds.left, bounds.top + bounds.height + 8),
      );
    } else {
      // X11: zero bounds — position at top-right fallback
      final display = await screenRetriever.getPrimaryDisplay();
      final screenWidth = display.size.width;
      await windowManager.setPosition(Offset(screenWidth - 340, 48));
    }
    await windowManager.show(inactive: true);
  }

  Future<void> hide() => windowManager.hide();
}
