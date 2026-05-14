import '../../../../core/errors/app_exception.dart';

// TtsFailure subtypes extend AppException so they are compatible with Result<T>.
sealed class TtsFailure extends AppException {
  const TtsFailure(super.message);
}

final class TtsEngineUnavailable extends TtsFailure {
  const TtsEngineUnavailable() : super('TTS engine unavailable');
}

final class TtsSpeakFailed extends TtsFailure {
  const TtsSpeakFailed(this.details) : super('TTS speak failed: $details');
  final String details;
}
