import '../../../../core/errors/app_exception.dart';

final class AiDisabled extends AppException {
  const AiDisabled() : super('AI explanation is disabled');
}

final class AiNetworkError extends AppException {
  const AiNetworkError(super.message);
}

final class AiParseError extends AppException {
  const AiParseError() : super('failed to parse AI response');
}
