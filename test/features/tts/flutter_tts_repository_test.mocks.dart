// ignore_for_file: type=lint
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mockito/mockito.dart' as _i1;
import 'package:speak_one/features/tts/data/datasources/tts_engine.dart'
    as _i2;

class MockTtsEngine extends _i1.Mock implements _i2.TtsEngine {
  MockTtsEngine() {
    _i1.throwOnMissingStub(this);
  }

  @override
  Future<dynamic> speak(String? text) =>
      (super.noSuchMethod(
            Invocation.method(#speak, [text]),
            returnValue: Future<dynamic>.value(),
          )
          as Future<dynamic>);

  @override
  Future<dynamic> stop() =>
      (super.noSuchMethod(
            Invocation.method(#stop, []),
            returnValue: Future<dynamic>.value(),
          )
          as Future<dynamic>);

  @override
  void setErrorHandler(void Function(dynamic) handler) =>
      super.noSuchMethod(
        Invocation.method(#setErrorHandler, [handler]),
        returnValueForMissingStub: null,
      );
}
