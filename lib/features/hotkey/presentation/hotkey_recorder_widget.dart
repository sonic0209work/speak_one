import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../data/hotkey_repository.dart';

class HotkeyRecorderWidget extends StatefulWidget {
  const HotkeyRecorderWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HotKey value;
  final ValueChanged<HotKey> onChanged;

  @override
  State<HotkeyRecorderWidget> createState() => _HotkeyRecorderWidgetState();
}

class _HotkeyRecorderWidgetState extends State<HotkeyRecorderWidget> {
  bool _recording = false;
  Timer? _cancelTimer;
  final _focusNode = FocusNode();
  Set<HotKeyModifier> _heldModifiers = {};

  static final _modifierPhysical = <PhysicalKeyboardKey, HotKeyModifier>{
    PhysicalKeyboardKey.controlLeft: HotKeyModifier.control,
    PhysicalKeyboardKey.controlRight: HotKeyModifier.control,
    PhysicalKeyboardKey.shiftLeft: HotKeyModifier.shift,
    PhysicalKeyboardKey.shiftRight: HotKeyModifier.shift,
    PhysicalKeyboardKey.altLeft: HotKeyModifier.alt,
    PhysicalKeyboardKey.altRight: HotKeyModifier.alt,
    PhysicalKeyboardKey.metaLeft: HotKeyModifier.meta,
    PhysicalKeyboardKey.metaRight: HotKeyModifier.meta,
  };

  void _startRecording() {
    GetIt.I<HotkeyRepository>().suspend();
    setState(() {
      _recording = true;
      _heldModifiers = {};
    });
    _focusNode.requestFocus();
    _cancelTimer = Timer(const Duration(seconds: 10), _stopRecording);
  }

  void _stopRecording() {
    _cancelTimer?.cancel();
    _cancelTimer = null;
    GetIt.I<HotkeyRepository>().resume();
    if (mounted) setState(() { _recording = false; _heldModifiers = {}; });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_recording) return KeyEventResult.ignored;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final mod = _modifierPhysical[event.physicalKey];
      if (mod != null) {
        setState(() => _heldModifiers.add(mod));
        return KeyEventResult.handled;
      }
      // Escape cancels recording without changing the hotkey.
      if (event.physicalKey == PhysicalKeyboardKey.escape) {
        _stopRecording();
        return KeyEventResult.handled;
      }
      // Non-modifier key: commit the combination.
      final hotkey = HotKey(
        key: event.physicalKey,
        modifiers: _heldModifiers.isEmpty ? null : _heldModifiers.toList(),
        scope: widget.value.scope,
      );
      _stopRecording();
      widget.onChanged(hotkey);
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      final mod = _modifierPhysical[event.physicalKey];
      if (mod != null) {
        // Only remove if no other physical key maps to the same modifier.
        final stillHeld = _modifierPhysical.entries
            .where((e) => e.value == mod && e.key != event.physicalKey)
            .any((e) => HardwareKeyboard.instance.physicalKeysPressed.contains(e.key));
        if (!stillHeld) setState(() => _heldModifiers.remove(mod));
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  String _modifierLabel(HotKeyModifier mod) => switch (mod) {
        HotKeyModifier.control => 'Ctrl',
        HotKeyModifier.shift => 'Shift',
        HotKeyModifier.alt => 'Alt',
        HotKeyModifier.meta => 'Super',
        _ => mod.name,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_recording) {
      final modLabel = _heldModifiers.isEmpty
          ? 'Press a key combination…'
          : '${_heldModifiers.map(_modifierLabel).join(' + ')} + ?';

      return Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.primary),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  modLabel,
                  style: TextStyle(fontSize: 13, color: scheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: _stopRecording, child: const Text('Cancel')),
          ],
        ),
      );
    }

    return Row(
      children: [
        HotKeyVirtualView(hotKey: widget.value),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _startRecording,
          child: const Text('Change'),
        ),
      ],
    );
  }
}
