import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:window_manager/window_manager.dart';

import 'app/panel_app.dart';
import 'core/di/service_locator.dart';
import 'core/services/isolate_service.dart';
import 'features/tray/tray_controller.dart';
import 'features/tray/tray_icon_service.dart';
import 'features/tts/domain/tts_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(320, 80),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: false,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.hide();
  });

  final trayIconService = GetIt.I<TrayIconService>();
  await trayIconService.init();

  GetIt.instance.registerSingleton<TrayController>(
    TrayController(
      isolateService: GetIt.I<IsolateService>(),
      trayIconService: trayIconService,
      ttsRepository: GetIt.I<TtsRepository>(),
    ),
  );

  runApp(const ProviderScope(child: PanelApp()));
}
