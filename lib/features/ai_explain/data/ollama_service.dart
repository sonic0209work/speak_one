import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../core/types/result.dart';
import '../../../features/settings/settings_service.dart';
import '../domain/failures/ai_explain_failure.dart';

class OllamaService {
  OllamaService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 60),
        ));

  final Dio _dio;

  static final _cjkRegex = RegExp(r'[一-鿿㐀-䶿]');

  Future<Result<String>> explain(String text) async {
    final settings = GetIt.I<SettingsService>();
    if (!settings.aiEnabled) return const Failure(AiDisabled());

    final baseUrl = settings.ollamaUrl;
    final model = settings.ollamaModel;
    final responseLang = settings.targetLang == 'auto' || settings.targetLang.isEmpty
        ? (_cjkRegex.hasMatch(text) ? 'English' : '繁體中文')
        : _langName(settings.targetLang);

    final prompt = '''You are a concise language tutor. The user selected this text:
"$text"

Explain briefly (3–5 lines):
- What it means
- Part of speech (if a single word or short phrase)
- One natural example sentence

Respond entirely in $responseLang.''';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/chat',
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': false,
        },
      );
      final content =
          response.data?['message']?['content'] as String?;
      if (content != null && content.isNotEmpty) {
        return Success(content.trim());
      }
      return const Failure(AiParseError());
    } on DioException catch (e) {
      return Failure(AiNetworkError(e.message ?? 'network error'));
    } catch (_) {
      return const Failure(AiParseError());
    }
  }

  static String _langName(String code) => switch (code) {
        'zh-TW' => '繁體中文',
        'zh-CN' => '简体中文',
        'ja' => '日本語',
        'ko' => '한국어',
        'fr' => 'French',
        'de' => 'German',
        'es' => 'Spanish',
        _ => 'English',
      };
}
