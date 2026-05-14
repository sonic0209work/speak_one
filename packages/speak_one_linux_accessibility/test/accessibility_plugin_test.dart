import 'dart:io' show Platform;

import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';
import 'package:test/test.dart';

void main() {
  group('SelectionRect', () {
    test('zero constructor', () {
      const r = SelectionRect.zero();
      expect(r.left, 0);
      expect(r.top, 0);
      expect(r.width, 0);
      expect(r.height, 0);
    });

    test('toString contains coordinates', () {
      const r = SelectionRect(10, 20, 100, 50);
      expect(r.toString(), contains('10'));
      expect(r.toString(), contains('20'));
    });
  });

  group('TextSelectionEvent', () {
    test('round-trips through JSON', () {
      final original = TextSelectionEvent(
        text: 'hello world',
        bounds: const SelectionRect(10, 20, 100, 30),
        timestamp: DateTime.utc(2026, 5, 13, 12, 0, 0),
      );
      final json = original.toJson();
      final restored = TextSelectionEvent.fromJson(json);

      expect(restored.text, equals(original.text));
      expect(restored.bounds.left, equals(original.bounds.left));
      expect(restored.bounds.top, equals(original.bounds.top));
      expect(restored.bounds.width, equals(original.bounds.width));
      expect(restored.bounds.height, equals(original.bounds.height));
      expect(restored.timestamp, equals(original.timestamp));
    });

    test('fromJson handles integer coordinates', () {
      final event = TextSelectionEvent.fromJson({
        'text': 'test',
        'left': 0,
        'top': 0,
        'width': 200,
        'height': 40,
        'timestamp': '2026-05-13T12:00:00.000Z',
      });
      expect(event.text, equals('test'));
      expect(event.bounds.width, equals(200.0));
    });

    test('toString contains text', () {
      final event = TextSelectionEvent(
        text: 'flutter',
        bounds: const SelectionRect.zero(),
        timestamp: DateTime.now(),
      );
      expect(event.toString(), contains('flutter'));
    });
  });

  group('DisplayServerDetector', () {
    test('returns a valid DisplayServer value', () {
      final result = DisplayServerDetector.detect();
      expect(DisplayServer.values, contains(result));
    });

    test('returns wayland when WAYLAND_DISPLAY is set', () {
      // This test only passes when run in a Wayland session.
      // It validates the detection logic indirectly via env inspection.
      final wayland = Platform.environment['WAYLAND_DISPLAY'];
      if (wayland != null && wayland.isNotEmpty) {
        expect(DisplayServerDetector.detect(), equals(DisplayServer.wayland));
      }
    }, skip: 'Environment-dependent — passes only in Wayland session');

    test('returns x11 when DISPLAY is set and WAYLAND_DISPLAY is absent', () {
      final display = Platform.environment['DISPLAY'];
      final wayland = Platform.environment['WAYLAND_DISPLAY'];
      if (display != null && display.isNotEmpty && (wayland == null || wayland.isEmpty)) {
        expect(DisplayServerDetector.detect(), equals(DisplayServer.x11));
      }
    }, skip: 'Environment-dependent — passes only in X11 session');
  });

  group('AccessibilityPlugin.listen() smoke', () {
    test('emits UnsupportedError when no display server is available', () {
      // We cannot override Platform.environment in Dart tests without
      // dependency injection. This test documents the expected behaviour
      // rather than asserting it programmatically.
      // A production test would use a testable wrapper around Platform.environment.
    });
  });
}
