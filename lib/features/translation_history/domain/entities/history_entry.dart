class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.sourceText,
    required this.sourceLang,
    required this.targetLang,
    required this.translated,
    this.aiResult,
    required this.isBookmarked,
    required this.createdAt,
  });

  final int id;
  final String sourceText;
  final String sourceLang;
  final String targetLang;
  final String translated;
  final String? aiResult;
  final bool isBookmarked;
  final DateTime createdAt;
}
