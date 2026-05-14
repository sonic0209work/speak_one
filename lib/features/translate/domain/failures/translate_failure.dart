import '../../../../core/errors/app_exception.dart';

sealed class TranslateFailure extends AppException {
  const TranslateFailure(super.message);
}

final class TranslateNetworkError extends TranslateFailure {
  const TranslateNetworkError(this.details) : super('Translate network error: $details');
  final String details;
}

final class TranslateParseError extends TranslateFailure {
  const TranslateParseError() : super('Translate response parse failed');
}
