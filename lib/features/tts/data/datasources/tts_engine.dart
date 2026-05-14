abstract interface class TtsEngine {
  Future<dynamic> speak(String text);
  Future<dynamic> stop();
  void setErrorHandler(void Function(dynamic message) handler);
}
