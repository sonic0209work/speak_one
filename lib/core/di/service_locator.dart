import 'package:get_it/get_it.dart';

import '../services/isolate_service.dart';
import '../../features/tray/tray_icon_service.dart';
import '../../features/tts/data/datasources/spd_say_engine.dart';
import '../../features/tts/data/repositories/flutter_tts_repository.dart';
import '../../features/tts/domain/tts_repository.dart';

void setupServiceLocator() {
  final gi = GetIt.instance;
  gi.registerSingleton<IsolateService>(IsolateService());
  gi.registerSingleton<TtsRepository>(FlutterTtsRepository(SpdSayEngine()));
  gi.registerSingleton<TrayIconService>(TrayIconService());
}
