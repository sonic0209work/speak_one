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
  static const _paddingV = 32.0;
  static const _minH = 120.0;
  static const _maxH = 560.0;

  late int _remaining;
  Timer? _dismissTimer;
  Timer? _dotsTimer;
  int _dotCount = 0;
  final _contentKey = GlobalKey();

  AppWindowController get _ctrl => GetIt.I<AppWindowController>();

  @override
  void initState() {
    super.initState();
    _remaining = _autoDismissSecs;
    _dismissTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _close();
    });
    _ctrl.addListener(_onCtrlChanged);
    if (_ctrl.isAiThinking) _startDots();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resizeToContent());
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrlChanged);
    _dismissTimer?.cancel();
    _dotsTimer?.cancel();
    super.dispose();
  }

  void _onCtrlChanged() {
    if (!mounted) return;
    if (!_ctrl.isAiThinking) _stopDots();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _resizeToContent());
  }

  void _startDots() {
    _dotsTimer?.cancel();
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _dotCount++);
    });
  }

  void _stopDots() {
    _dotsTimer?.cancel();
    _dotsTimer = null;
  }

  void _close() => _ctrl.hideWindow();

  Future<void> _resizeToContent() async {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final h = (_appBarH + _paddingV + box.size.height).clamp(_minH, _maxH);
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
    final translation = _ctrl.translation;
    final explanation = _ctrl.explanation;
    final isThinking = _ctrl.isAiThinking;
    final preview =
        original.length > 50 ? '${original.substring(0, 50)}…' : original;
    final dots = '.' * (_dotCount % 3 + 1);

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
            // Translation
            SelectableText(
              translation,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
            ),
            // AI section
            if (isThinking || explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 8),
              if (isThinking)
                Text(
                  'thinking$dots',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                SelectableText(
                  explanation,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
