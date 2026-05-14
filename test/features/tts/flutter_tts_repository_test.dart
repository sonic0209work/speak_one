import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:speak_one/core/types/result.dart';
import 'package:speak_one/features/tts/data/datasources/tts_engine.dart';
import 'package:speak_one/features/tts/data/repositories/flutter_tts_repository.dart';
import 'package:speak_one/features/tts/domain/failures/tts_failure.dart';
import 'package:test/test.dart';

import 'flutter_tts_repository_test.mocks.dart';

@GenerateMocks([TtsEngine])
void main() {
  group('FlutterTtsRepository', () {
    late MockTtsEngine mockEngine;
    late FlutterTtsRepository repo;

    setUp(() {
      mockEngine = MockTtsEngine();
      repo = FlutterTtsRepository(mockEngine);
    });

    test('speak returns Success when engine returns 1', () async {
      when(mockEngine.speak(any)).thenAnswer((_) async => 1);
      final result = await repo.speak('hello');
      expect(result, isA<Success<void>>());
    });

    test('speak returns Failure when engine returns non-1', () async {
      when(mockEngine.speak(any)).thenAnswer((_) async => 0);
      final result = await repo.speak('hello');
      expect(result, isA<Failure<void>>());
      expect((result as Failure).error, isA<TtsSpeakFailed>());
    });

    test('speak returns Failure when engine throws', () async {
      when(mockEngine.speak(any)).thenThrow(Exception('engine error'));
      final result = await repo.speak('hello');
      expect(result, isA<Failure<void>>());
    });

    test('stop swallows exceptions', () async {
      when(mockEngine.stop()).thenThrow(Exception('stop failed'));
      await expectLater(repo.stop(), completes);
    });
  });
}
