import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speak_one_linux_accessibility/speak_one_linux_accessibility.dart';

class CurrentSelectionNotifier extends Notifier<TextSelectionEvent?> {
  @override
  TextSelectionEvent? build() => null;

  void update(TextSelectionEvent event) => state = event;
}

final currentSelectionProvider =
    NotifierProvider<CurrentSelectionNotifier, TextSelectionEvent?>(
        CurrentSelectionNotifier.new);
