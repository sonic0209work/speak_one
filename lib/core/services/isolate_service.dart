import 'dart:async';

import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

class IsolateService {
  IsolateService() {
    _stream = AccessibilityPlugin.listen().asBroadcastStream();
  }

  late final Stream<TextSelectionEvent> _stream;

  Stream<TextSelectionEvent> get events => _stream;
}
