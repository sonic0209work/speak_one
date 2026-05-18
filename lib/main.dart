import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app_window_controller.dart';
import 'app/panel_app.dart';
import 'core/di/service_locator.dart';
import 'core/services/isolate_service.dart';
import 'features/ai_explain/data/ollama_service.dart';
import 'features/hotkey/data/hotkey_repository.dart';
import 'features/notification/notification_service.dart';
import 'features/ocr_capture/data/ocr_capture_service.dart';
import 'features/translate/data/translate_service.dart';
import 'features/tray/tray_controller.dart';
import 'features/tray/tray_icon_service.dart';
import 'features/tts/domain/tts_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(420, 520),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    alwaysOnTop: true,
    title: 'Speak One',
  );
  // Must show once to map the GTK window before hide/show will work reliably.
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.hide();
  });

  final trayIconService = GetIt.I<TrayIconService>();
  await trayIconService.init();

  final appWindowController = GetIt.I<AppWindowController>();
  trayIconService.onSettingsRequested = () => appWindowController.showSettings();

  GetIt.instance.registerSingleton<TrayController>(
    TrayController(
      isolateService: GetIt.I<IsolateService>(),
      trayIconService: trayIconService,
      ttsRepository: GetIt.I<TtsRepository>(),
      translateService: GetIt.I<TranslateService>(),
      notificationService: GetIt.I<NotificationService>(),
      ollamaService: GetIt.I<OllamaService>(),
      appWindowController: appWindowController,
      hotkeyRepository: GetIt.I<HotkeyRepository>(),
      ocrCaptureService: GetIt.I<OcrCaptureService>(),
    ),
  );

  runApp(const ProviderScope(child: PanelApp()));
}
