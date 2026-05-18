import 'dart:async';

import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/types/result.dart';

class HotkeyRepository {
  final _controller = StreamController<void>.broadcast();
  HotKey? _registered;

  Stream<void> get activations => _controller.stream;

  Future<void> init(HotKey hotkey) async {
    _registered = hotkey;
    await hotKeyManager.register(
      hotkey,
      keyDownHandler: (_) => _controller.add(null),
    );
  }

  Future<Result<void>> update(HotKey hotkey) async {
    try {
      if (_registered != null) {
        await hotKeyManager.unregister(_registered!);
      }
      _registered = hotkey;
      await hotKeyManager.register(
        hotkey,
        keyDownHandler: (_) => _controller.add(null),
      );
      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to register hotkey: $e'));
    }
  }

  Future<void> dispose() async {
    if (_registered != null) {
      await hotKeyManager.unregister(_registered!);
    }
    await _controller.close();
  }
}
