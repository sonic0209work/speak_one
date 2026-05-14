import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import '../settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = GetIt.I<SettingsService>();

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

  @override
  void initState() {
    super.initState();
    _sourceLang = _settings.sourceLang;
    _targetLang = _settings.targetLang;
  }

  Future<void> _save() async {
    await _settings.setSourceLang(_sourceLang);
    await _settings.setTargetLang(_targetLang);
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LangRow(
              label: 'Source language',
              value: _sourceLang,
              options: _langOptions,
              onChanged: (v) => setState(() => _sourceLang = v),
            ),
            const SizedBox(height: 16),
            _LangRow(
              label: 'Target language',
              value: _targetLang,
              options: _langOptions.where((e) => e.$1 != 'auto').toList(),
              onChanged: (v) => setState(() => _targetLang = v),
            ),
            const SizedBox(height: 32),
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
