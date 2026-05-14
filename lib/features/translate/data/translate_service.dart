import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../core/types/result.dart';
import '../../../features/settings/settings_service.dart';
import '../domain/failures/translate_failure.dart';

class TranslateService {
  TranslateService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  final Dio _dio;

  static final _cjkRegex = RegExp(r'[一-鿿㐀-䶿]');

  Future<Result<String>> translate(String text) async {
    final settings = GetIt.I<SettingsService>();
    final savedTarget = settings.targetLang;
    // If user picked a fixed target, use it. Otherwise auto-detect by script.
    final tl = savedTarget.isNotEmpty
        ? savedTarget
        : (_cjkRegex.hasMatch(text) ? 'en' : 'zh-TW');
    final sl = settings.sourceLang;
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': sl,
          'tl': tl,
          'dt': 't',
          'q': text,
        },
      );
      final data = response.data;
      final translation =
          (data != null && data[0] is List && (data[0] as List)[0] is List)
              ? ((data[0] as List)[0] as List)[0] as String?
              : null;
      if (translation != null && translation.isNotEmpty) {
        return Success(translation);
      }
      return const Failure(TranslateParseError());
    } on DioException catch (e) {
      return Failure(TranslateNetworkError(e.message ?? 'unknown'));
    } catch (_) {
      return const Failure(TranslateParseError());
    }
  }
}
