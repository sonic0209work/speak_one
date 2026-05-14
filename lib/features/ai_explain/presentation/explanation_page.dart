import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/app_window_controller.dart';

class ExplanationPage extends StatefulWidget {
  const ExplanationPage({super.key});

  @override
  State<ExplanationPage> createState() => _ExplanationPageState();
}

class _ExplanationPageState extends State<ExplanationPage> {
  static const _autoDismissSecs = 20;
  static const _windowWidth = 420.0;
  static const _appBarH = 56.0;
  static const _paddingV = 32.0; // 16 top + 16 bottom
  static const _minH = 160.0;
  static const _maxH = 560.0;

  late int _remaining;
  Timer? _timer;
  final _contentKey = GlobalKey();

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _resizeToContent());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() => _ctrl.hideWindow();

  Future<void> _resizeToContent() async {
    final box =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final h = (_appBarH + _paddingV + box.size.height)
        .clamp(_minH, _maxH);

    await windowManager.setMinimumSize(Size(_windowWidth, h));
    await windowManager.setSize(Size(_windowWidth, h));
    await _repositionBottomRight(h);
  }

  Future<void> _repositionBottomRight(double windowH) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final screen = display.size;
      const margin = 16.0;
      const taskbar = 48.0;
      await windowManager.setPosition(Offset(
        screen.width - _windowWidth - margin,
        screen.height - windowH - margin - taskbar,
      ));
    } catch (_) {
      await windowManager.setAlignment(Alignment.bottomRight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final original = _ctrl.original;
    final explanation = _ctrl.explanation;
    final preview =
        original.length > 50 ? '${original.substring(0, 50)}…' : original;

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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
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
        child: Column(
          key: _contentKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              explanation,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
