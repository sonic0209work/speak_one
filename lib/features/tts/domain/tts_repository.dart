import '../../../core/types/result.dart';

abstract interface class TtsRepository {
  Future<Result<void>> speak(String text);
  Future<void> stop();
}
