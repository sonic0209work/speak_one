import 'dart:async';

import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

import '../../../../core/constants/k_app_constants.dart';

class SelectionFilterService {
  final _controller = StreamController<TextSelectionEvent>.broadcast();
  Timer? _debounce;
  StreamSubscription<TextSelectionEvent>? _subscription;

  Stream<TextSelectionEvent> filter(Stream<TextSelectionEvent> input) {
    _subscription = input.listen(
      (event) {
if (event.text.length < kMinTextLength) return;
        _debounce?.cancel();
        _debounce = Timer(kDebounceDelay, () => _controller.add(event));
      },
      onError: _controller.addError,
    );
    return _controller.stream;
  }

  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _controller.close();
  }
}
