import 'dart:async';

import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

class IsolateService {
  IsolateService() {
    _connect();
  }

  final _controller = StreamController<TextSelectionEvent>.broadcast();
  StreamSubscription<TextSelectionEvent>? _sub;
  Timer? _restartTimer;

  Stream<TextSelectionEvent> get events => _controller.stream;

  void _connect() {
    _sub?.cancel();
    _sub = AccessibilityPlugin.listen().listen(
      _controller.add,
      onError: (_) => _scheduleRestart(),
      onDone: _scheduleRestart,
      cancelOnError: false,
    );
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 3), _connect);
  }
}
