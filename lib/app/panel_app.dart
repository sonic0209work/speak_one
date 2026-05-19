import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import 'app_window_controller.dart';
import '../features/ai_explain/presentation/explanation_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/translation_history/presentation/history_page.dart';

class PanelApp extends StatefulWidget {
  const PanelApp({super.key});

  @override
  State<PanelApp> createState() => _PanelAppState();
}

class _PanelAppState extends State<PanelApp> with WindowListener {
  final _ctrl = GetIt.I<AppWindowController>();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async => await _ctrl.hideWindow();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: ListenableBuilder(
        listenable: _ctrl,
        builder: (_, _) => switch (_ctrl.view) {
          WindowView.explanation => ExplanationPage(
              key: ValueKey(_ctrl.explanationGeneration),
            ),
          WindowView.history => const HistoryPage(),
          _ => const SettingsPage(),
        },
      ),
    );
  }
}
