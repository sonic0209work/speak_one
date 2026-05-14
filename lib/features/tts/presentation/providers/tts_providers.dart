import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../domain/tts_repository.dart';
import '../../../../core/types/result.dart';

class TtsNotifier extends AsyncNotifier<void> {
  late final TtsRepository _repository;

  @override
  Future<void> build() async {
    _repository = GetIt.I<TtsRepository>();
  }

  Future<void> speak(String text) async {
    state = const AsyncLoading();
    await _repository.stop();
    final result = await _repository.speak(text);
    state = switch (result) {
      Success() => const AsyncData(null),
      Failure(:final error) => AsyncError(error, StackTrace.current),
    };
  }
}

final ttsStateProvider =
    AsyncNotifierProvider<TtsNotifier, void>(TtsNotifier.new);
