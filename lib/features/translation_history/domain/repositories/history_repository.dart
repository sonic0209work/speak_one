import '../entities/history_entry.dart';

abstract interface class HistoryRepository {
  /// Inserts a new record and returns its row ID.
  Future<int> add({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
    required String translated,
    String? aiResult,
  });

  Future<void> updateAiResult(int id, String aiResult);

  Future<void> setBookmark(int id, {required bool bookmarked});

  Future<void> delete(int id);

  Future<void> deleteAll();

  Future<List<HistoryItem>> getAll({String? query});

  /// Deletes all records whose [expiresAt] is in the past.
  Future<int> pruneExpired();

  /// Returns a cached translation for [sourceText] if a bookmarked record
  /// with matching normalized key exists. Returns null on miss.
  Future<HistoryItem?> findCached({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
  });
}
