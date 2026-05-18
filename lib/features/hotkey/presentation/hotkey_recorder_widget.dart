import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

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

  void _startRecording() {
    setState(() => _recording = true);
    _cancelTimer = Timer(const Duration(seconds: 10), _stopRecording);
  }

  void _stopRecording() {
    _cancelTimer?.cancel();
    _cancelTimer = null;
    if (mounted) setState(() => _recording = false);
  }

  void _onRecorded(HotKey hotkey) {
    _stopRecording();
    widget.onChanged(hotkey);
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_recording) {
      return Row(
        children: [
          Expanded(
            child: HotKeyRecorder(
              initalHotKey: widget.value,
              onHotKeyRecorded: _onRecorded,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: _stopRecording, child: const Text('Cancel')),
        ],
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
