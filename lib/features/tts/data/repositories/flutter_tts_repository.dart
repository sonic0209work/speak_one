import '../../../../core/types/result.dart';
import '../../domain/failures/tts_failure.dart';
import '../../domain/tts_repository.dart';
import '../datasources/tts_engine.dart';

class FlutterTtsRepository implements TtsRepository {
  FlutterTtsRepository(TtsEngine engine) : _engine = engine {
    _engine.setErrorHandler((message) => _lastError = message?.toString());
  }

  final TtsEngine _engine;
  String? _lastError;

  @override
  Future<Result<void>> speak(String text) async {
    _lastError = null;
    try {
      final result = await _engine.speak(text);
      if (result != 1) {
        return Failure(TtsSpeakFailed(_lastError ?? 'speak returned $result'));
      }
      return const Success(null);
    } catch (e) {
      return Failure(TtsSpeakFailed(e.toString()));
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {}
  }
}
