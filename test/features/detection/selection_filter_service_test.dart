import 'dart:async';

import 'package:test/test.dart';
import 'package:speak_one/features/detection/domain/services/selection_filter_service.dart';
import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

TextSelectionEvent _event(String text) => TextSelectionEvent(
      text: text,
      bounds: const SelectionRect.zero(),
      timestamp: DateTime.now().toUtc(),
    );

void main() {
  group('SelectionFilterService', () {
    late SelectionFilterService service;
    late StreamController<TextSelectionEvent> input;

    setUp(() {
      service = SelectionFilterService();
      input = StreamController<TextSelectionEvent>();
    });

    tearDown(() {
      service.dispose();
      input.close();
    });

    test('drops events shorter than kMinTextLength', () async {
      final output = service.filter(input.stream);
      final received = <TextSelectionEvent>[];
      final sub = output.listen(received.add);

      input.add(_event('a')); // length 1 — filtered
      input.add(_event(' ')); // length 1 — filtered

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(received, isEmpty);
      await sub.cancel();
    });

    test('emits event after debounce window', () async {
      final output = service.filter(input.stream);
      final received = <TextSelectionEvent>[];
      final sub = output.listen(received.add);

      input.add(_event('hello'));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(received.length, 1);
      expect(received.first.text, 'hello');
      await sub.cancel();
    });

    test('rapid events within debounce window emit only the last', () async {
      final output = service.filter(input.stream);
      final received = <TextSelectionEvent>[];
      final sub = output.listen(received.add);

      input.add(_event('first'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      input.add(_event('second'));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(received.length, 1);
      expect(received.first.text, 'second');
      await sub.cancel();
    });
  });
}
