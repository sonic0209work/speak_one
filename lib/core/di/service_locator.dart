import 'package:get_it/get_it.dart';

import '../../app/app_window_controller.dart';
import '../../core/database/app_database.dart';
import '../services/isolate_service.dart';
import '../../features/ai_explain/data/ollama_service.dart';
import '../../features/autostart/autostart_service.dart';
import '../../features/hotkey/data/hotkey_repository.dart';
import '../../features/notification/notification_service.dart';
import '../../features/ocr_capture/data/ocr_capture_service.dart';
import '../../features/settings/settings_service.dart';
import '../../features/translate/data/translate_service.dart';
import '../../features/translation_history/data/repositories/history_repository_impl.dart';
import '../../features/translation_history/domain/repositories/history_repository.dart';
import '../../features/tray/tray_icon_service.dart';
import '../../features/tts/data/datasources/google_tts_engine.dart';
import '../../features/tts/data/repositories/flutter_tts_repository.dart';
import '../../features/tts/domain/tts_repository.dart';

Future<void> setupServiceLocator() async {
  final gi = GetIt.instance;
  final settings = SettingsService();
  await settings.init();
  gi.registerSingleton<SettingsService>(settings);
  gi.registerSingleton<AppDatabase>(AppDatabase());
  gi.registerSingleton<HistoryRepository>(HistoryRepositoryImpl());
  gi.registerSingleton<IsolateService>(IsolateService());
  gi.registerSingleton<TtsRepository>(FlutterTtsRepository(GoogleTtsEngine()));
  gi.registerSingleton<TranslateService>(TranslateService());
  gi.registerSingleton<NotificationService>(NotificationService());
  gi.registerSingleton<OllamaService>(OllamaService());
  gi.registerSingleton<AutostartService>(AutostartService());
  gi.registerSingleton<AppWindowController>(AppWindowController());
  gi.registerSingleton<TrayIconService>(TrayIconService());

  final hotkeyRepo = HotkeyRepository();
  await hotkeyRepo.init(settings.hotkeyConfig);
  gi.registerSingleton<HotkeyRepository>(hotkeyRepo);
  gi.registerSingleton<OcrCaptureService>(OcrCaptureService());
}
