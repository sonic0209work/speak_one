import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/app_window_controller.dart';
import '../../settings/settings_service.dart';

class ExplanationPage extends StatefulWidget {
  const ExplanationPage({super.key});

  @override
  State<ExplanationPage> createState() => _ExplanationPageState();
}

class _ExplanationPageState extends State<ExplanationPage> {
  static const _autoDismissSecs = 20;
  static const _windowWidth = 420.0;
  static const _appBarH = 58.0; // 56 toolbar + 2 countdown bar
  static const _paddingV = 32.0;
  static const _minH = 120.0;
  static const _maxH = 560.0;
  static const _fadeDuration = Duration(milliseconds: 250);

  late int _remaining;
  late String _activeLang;
  Timer? _dismissTimer;
  Timer? _dotsTimer;
  Timer? _resizeDebounce;
  int _dotCount = 0;
  bool _hovered = false;
  bool _pinned = false;
  bool _translationHovered = false;
  final _contentKey = GlobalKey();

  AppWindowController get _ctrl => GetIt.I<AppWindowController>();

  @override
  void initState() {
    super.initState();
    _remaining = _autoDismissSecs;
    _activeLang = GetIt.I<SettingsService>().targetLang;
    _dismissTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_hovered || _pinned) return;
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
    _resizeDebounce?.cancel();
    super.dispose();
  }

  void _onCtrlChanged() {
    if (!mounted) return;
    if (_ctrl.isAiThinking && _dotsTimer == null) _startDots();
    if (!_ctrl.isAiThinking) _stopDots();
    setState(() {});
    _scheduleResize();
  }

  void _scheduleResize() {
    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 80), () {
      if (mounted) _resizeToContent();
    });
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

  void _switchLang(String langCode) {
    if (_activeLang == langCode) return;
    setState(() => _activeLang = langCode);
    _ctrl.retranslate(langCode);
  }

  Future<void> _resizeToContent() async {
    if (!mounted) return;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final h = (_appBarH + _paddingV + box.size.height).clamp(_minH, _maxH);
    await windowManager.setMinimumSize(Size(_windowWidth, h));
    if (!mounted) return;
    await windowManager.setSize(Size(_windowWidth, h));
    if (!mounted) return;
    await _ctrl.repositionForSize(h);
  }

  @override
  Widget build(BuildContext context) {
    final original = _ctrl.original;
    final translation = _ctrl.translation;
    final explanation = _ctrl.explanation;
    final isTranslating = _ctrl.isTranslating;
    final isThinking = _ctrl.isAiThinking;
    final preview = original.length > 50 ? '${original.substring(0, 50)}…' : original;
    final dots = '.' * (_dotCount % 3 + 1);
    final scheme = Theme.of(context).colorScheme;
    final progressValue = (_remaining / _autoDismissSecs).clamp(0.0, 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Scaffold(
        appBar: AppBar(
          title: Text(preview, style: const TextStyle(fontSize: 13)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: LayoutBuilder(
              builder: (ctx, constraints) => Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.linear,
                  width: constraints.maxWidth * progressValue,
                  height: 2,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 16,
              ),
              onPressed: () => setState(() {
                _pinned = !_pinned;
                if (_pinned) _remaining = _autoDismissSecs;
              }),
              tooltip: _pinned ? 'Unpin' : 'Pin',
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _close,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTranslating) const LinearProgressIndicator(minHeight: 2),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  key: _contentKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Translation card + language bar
                    AnimatedSwitcher(
                      duration: _fadeDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: translation.isNotEmpty
                          ? Column(
                              key: const ValueKey('translation-section'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TranslationCard(
                                  text: translation,
                                  hovered: _translationHovered,
                                  onHoverChange: (v) => setState(
                                      () => _translationHovered = v),
                                ),
                                const SizedBox(height: 8),
                                _LangBar(
                                  activeLang: _activeLang,
                                  onSelect: _switchLang,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // AI section (divider + thinking/explanation)
                    AnimatedSwitcher(
                      duration: _fadeDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: (isThinking || explanation.isNotEmpty)
                          ? Column(
                              key: const ValueKey('ai-section'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                const _AiDivider(),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: _fadeDuration,
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                          opacity: animation, child: child),
                                  child: isThinking
                                      ? Text(
                                          key: const ValueKey('thinking'),
                                          'thinking$dots',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: scheme.onSurface
                                                .withValues(alpha: 0.45),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      : Padding(
                                          key: const ValueKey('explanation'),
                                          padding:
                                              const EdgeInsets.only(left: 4),
                                          child: SelectableText(
                                            explanation,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.6,
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslationCard extends StatelessWidget {
  const _TranslationCard({
    required this.text,
    required this.hovered,
    required this.onHoverChange,
  });

  final String text;
  final bool hovered;
  final ValueChanged<bool> onHoverChange;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: hovered ? 1.0 : 0.0,
              child: Tooltip(
                message: 'Copy',
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => Clipboard.setData(ClipboardData(text: text)),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy_outlined, size: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangBar extends StatelessWidget {
  const _LangBar({required this.activeLang, required this.onSelect});

  final String activeLang;
  final ValueChanged<String> onSelect;

  static const _langs = [
    ('zh-TW', '繁中'),
    ('zh-CN', '簡中'),
    ('en', 'EN'),
    ('ja', 'JP'),
    ('ko', 'KR'),
    ('fr', 'FR'),
    ('de', 'DE'),
    ('es', 'ES'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (code, label) in _langs)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onSelect(code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: activeLang == code
                        ? scheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeLang == code
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: activeLang == code
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: activeLang == code
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiDivider extends StatelessWidget {
  const _AiDivider();

  @override
  Widget build(BuildContext context) {
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return Row(
      children: [
        Expanded(
            child: Divider(color: Theme.of(context).dividerColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '✦ AI 說明',
            style: TextStyle(fontSize: 11, color: dimColor),
          ),
        ),
        Expanded(
            child: Divider(color: Theme.of(context).dividerColor, height: 1)),
      ],
    );
  }
}
