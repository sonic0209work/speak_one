import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../../app/app_window_controller.dart';
import '../../autostart/autostart_service.dart';
import '../../hotkey/data/hotkey_repository.dart';
import '../../hotkey/presentation/hotkey_recorder_widget.dart';
import '../settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _windowWidth = 420.0;
  static const _appBarH = 56.0;
  static const _paddingV = 40.0; // fromLTRB(24, 16, 24, 24) → 16 + 24
  static const _minH = 200.0;
  static const _maxH = 720.0;

  final _contentKey = GlobalKey();
  final _settings = GetIt.I<SettingsService>();
  final _autostart = GetIt.I<AutostartService>();
  final _ocrHotkeyRepo = GetIt.I<HotkeyRepository>(instanceName: 'ocr');
  final _selectionHotkeyRepo = GetIt.I<HotkeyRepository>(instanceName: 'selection');
  final _ctrl = GetIt.I<AppWindowController>();

  static const _langOptions = [
    ('auto', 'Auto-detect'),
    ('en', 'English'),
    ('zh-TW', '繁體中文'),
    ('zh-CN', '简体中文'),
    ('ja', '日本語'),
    ('ko', '한국어'),
    ('fr', 'Français'),
    ('de', 'Deutsch'),
    ('es', 'Español'),
  ];

  late String _sourceLang;
  late String _targetLang;
  late bool _aiEnabled;
  late TextEditingController _ollamaUrl;
  late TextEditingController _ollamaModel;
  bool _autostartEnabled = false;
  late HotKey _hotkeyConfig;
  late HotKey _selectionHotkeyConfig;
  late int _historyRetentionDays;

  @override
  void initState() {
    super.initState();
    _sourceLang = _settings.sourceLang;
    _targetLang = _settings.targetLang;
    _aiEnabled = _settings.aiEnabled;
    _ollamaUrl = TextEditingController(text: _settings.ollamaUrl);
    _ollamaModel = TextEditingController(text: _settings.ollamaModel);
    _hotkeyConfig = _settings.hotkeyConfig;
    _selectionHotkeyConfig = _settings.selectionHotkeyConfig;
    _historyRetentionDays = _settings.historyRetentionDays;
    _autostart.isEnabled().then((v) {
      if (mounted) setState(() => _autostartEnabled = v);
    });
  }

  @override
  void dispose() {
    _ollamaUrl.dispose();
    _ollamaModel.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _settings.setSourceLang(_sourceLang);
    await _settings.setTargetLang(_targetLang);
    await _settings.setAiEnabled(_aiEnabled);
    await _settings.setOllamaUrl(_ollamaUrl.text.trim());
    await _settings.setOllamaModel(_ollamaModel.text.trim());
    await _settings.setHotkeyConfig(_hotkeyConfig);
    await _ocrHotkeyRepo.update(_hotkeyConfig);
    await _settings.setSelectionHotkeyConfig(_selectionHotkeyConfig);
    await _selectionHotkeyRepo.update(_selectionHotkeyConfig);
    await _settings.setHistoryRetentionDays(_historyRetentionDays);
    if (_autostartEnabled) {
      await _autostart.enable();
    } else {
      await _autostart.disable();
    }
    await _ctrl.hideWindow();
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
    await windowManager.setAlignment(Alignment.center);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _resizeToContent());
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          key: _contentKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Translation'),
            const SizedBox(height: 8),
            _LangRow(
              label: 'Source language',
              value: _sourceLang,
              options: _langOptions,
              onChanged: (v) => setState(() => _sourceLang = v),
            ),
            const SizedBox(height: 12),
            _LangRow(
              label: 'Target language',
              value: _targetLang,
              options: _langOptions.where((e) => e.$1 != 'auto').toList(),
              onChanged: (v) => setState(() => _targetLang = v),
            ),
            const SizedBox(height: 20),
            _sectionLabel('AI Explanation (Ollama)'),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 140, child: Text('Enable AI')),
                Switch(
                  value: _aiEnabled,
                  onChanged: (v) => setState(() => _aiEnabled = v),
                ),
              ],
            ),
            if (_aiEnabled) ...[
              const SizedBox(height: 12),
              _TextField(label: 'Ollama URL', controller: _ollamaUrl),
              const SizedBox(height: 12),
              _TextField(label: 'Model', controller: _ollamaModel),
            ],
            const SizedBox(height: 20),
            _sectionLabel('Capture'),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 140, child: Text('Selection hotkey')),
                Expanded(
                  child: HotkeyRecorderWidget(
                    value: _selectionHotkeyConfig,
                    repoInstanceName: 'selection',
                    onChanged: (v) => setState(() => _selectionHotkeyConfig = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 140, child: Text('OCR hotkey')),
                Expanded(
                  child: HotkeyRecorderWidget(
                    value: _hotkeyConfig,
                    repoInstanceName: 'ocr',
                    onChanged: (v) => setState(() => _hotkeyConfig = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionLabel('History'),
            const SizedBox(height: 8),
            _LangRow(
              label: 'Keep history for',
              value: _historyRetentionDays.toString(),
              options: const [
                ('7', '7 days'),
                ('14', '14 days'),
                ('30', '30 days'),
                ('60', '60 days'),
                ('90', '90 days'),
              ],
              onChanged: (v) =>
                  setState(() => _historyRetentionDays = int.parse(v)),
            ),
            const SizedBox(height: 20),
            _sectionLabel('System'),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 140, child: Text('Launch at login')),
                Switch(
                  value: _autostartEnabled,
                  onChanged: (v) => setState(() => _autostartEnabled = v),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      );
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: options.any((e) => e.$1 == value) ? value : options.first.$1,
            items: options
                .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                .toList(),
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}
