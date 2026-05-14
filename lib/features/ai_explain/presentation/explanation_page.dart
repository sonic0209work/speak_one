import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../app/app_window_controller.dart';

class ExplanationPage extends StatefulWidget {
  const ExplanationPage({super.key});

  @override
  State<ExplanationPage> createState() => _ExplanationPageState();
}

class _ExplanationPageState extends State<ExplanationPage> {
  static const _autoDismissSecs = 20;
  late int _remaining;
  Timer? _timer;

  AppWindowController get _ctrl => GetIt.I<AppWindowController>();

  @override
  void initState() {
    super.initState();
    _remaining = _autoDismissSecs;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _close();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() => _ctrl.hideWindow();

  @override
  Widget build(BuildContext context) {
    final original = _ctrl.original;
    final explanation = _ctrl.explanation;
    final preview = original.length > 50
        ? '${original.substring(0, 50)}…'
        : original;

    return Scaffold(
      appBar: AppBar(
        title: Text(preview, style: const TextStyle(fontSize: 13)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                '$_remaining s',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _close,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          explanation,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
