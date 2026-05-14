abstract class AppException {
  const AppException(this.message);
  final String message;
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class ApiException extends AppException {
  const ApiException(super.message, {required this.statusCode});
  final int statusCode;
}

final class ParseException extends AppException {
  const ParseException(super.message);
}

final class StorageException extends AppException {
  const StorageException(super.message);
}
