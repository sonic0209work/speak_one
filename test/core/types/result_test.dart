import 'package:test/test.dart';
import 'package:speak_one/core/errors/app_exception.dart';
import 'package:speak_one/core/types/result.dart';

void main() {
  group('Result', () {
    test('Success carries value', () {
      const result = Success(42);
      expect(result.value, 42);
    });

    test('Failure carries AppException', () {
      const result = Failure<int>(NetworkException('no connection'));
      expect(result.error, isA<NetworkException>());
      expect(result.error.message, 'no connection');
    });

    test('pattern-match is exhaustive', () {
      final Result<String> r = const Success('hello');
      final out = switch (r) {
        Success(:final value) => value,
        Failure(:final error) => error.message,
      };
      expect(out, 'hello');
    });
  });
}
