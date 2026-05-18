import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../../features/settings/settings_service.dart';

class OllamaService {
  OllamaService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 60),
        ));

  final Dio _dio;

  static final _cjkRegex = RegExp(r'[一-鿿㐀-䶿]');

  /// Streams text deltas from Ollama as the model generates tokens.
  /// Each yielded [String] is a new delta to be appended to the display.
  /// The stream closes normally on completion or cancellation.
  Stream<String> explainStream(String text, {CancelToken? cancelToken}) async* {
    final settings = GetIt.I<SettingsService>();
    if (!settings.aiEnabled) return;

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
      final response = await _dio.post<ResponseBody>(
        '$baseUrl/api/chat',
        data: {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      final lines = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.isEmpty) continue;
        final json = jsonDecode(line) as Map<String, dynamic>;
        if (json['done'] as bool? ?? false) break;
        final delta = (json['message']?['content'] as String?) ?? '';
        if (delta.isNotEmpty) yield delta;
      }
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) rethrow;
      // cancelled — stream closes silently
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
