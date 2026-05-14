import 'package:get_it/get_it.dart';

import '../services/isolate_service.dart';
import '../../features/notification/notification_service.dart';
import '../../features/settings/settings_service.dart';
import '../../features/translate/data/translate_service.dart';
import '../../features/tray/tray_icon_service.dart';
import '../../features/tts/data/datasources/google_tts_engine.dart';
import '../../features/tts/data/repositories/flutter_tts_repository.dart';
import '../../features/tts/domain/tts_repository.dart';

Future<void> setupServiceLocator() async {
  final gi = GetIt.instance;
  final settings = SettingsService();
  await settings.init();
  gi.registerSingleton<SettingsService>(settings);
  gi.registerSingleton<IsolateService>(IsolateService());
  gi.registerSingleton<TtsRepository>(FlutterTtsRepository(GoogleTtsEngine()));
  gi.registerSingleton<TranslateService>(TranslateService());
  gi.registerSingleton<NotificationService>(NotificationService());
  gi.registerSingleton<TrayIconService>(TrayIconService());
}
