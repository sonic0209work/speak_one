import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  AppDatabase get _db => GetIt.I<AppDatabase>();

  static const _retentionDays = 30;

  static String _normalize(String text) => text.trim().toLowerCase();

  @override
  Future<int> add({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
    required String translated,
    String? aiResult,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + const Duration(days: _retentionDays).inMilliseconds;
    return _db.into(_db.historyEntries).insert(
          HistoryEntriesCompanion.insert(
            sourceText: sourceText,
            sourceLang: sourceLang,
            targetLang: targetLang,
            translated: translated,
            aiResult: Value(aiResult),
            createdAt: now,
            expiresAt: Value(expires),
          ),
        );
  }

  @override
  Future<void> updateAiResult(int id, String aiResult) async {
    await (_db.update(_db.historyEntries)
          ..where((t) => t.id.equals(id)))
        .write(HistoryEntriesCompanion(aiResult: Value(aiResult)));
  }

  @override
  Future<void> setBookmark(int id, {required bool bookmarked}) async {
    await (_db.update(_db.historyEntries)
          ..where((t) => t.id.equals(id)))
        .write(HistoryEntriesCompanion(
      isBookmarked: Value(bookmarked),
      // Bookmarked = never expires; un-bookmark restores the 30-day window.
      expiresAt: bookmarked
          ? const Value(null)
          : Value(DateTime.now()
                  .add(const Duration(days: _retentionDays))
                  .millisecondsSinceEpoch),
    ));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.historyEntries)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_db.historyEntries).go();
  }

  @override
  Future<List<HistoryItem>> getAll({String? query}) async {
    final q = _db.select(_db.historyEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await q.get();
    final items = rows.map(_toItem).toList();
    if (query == null || query.isEmpty) return items;
    final lower = query.toLowerCase();
    return items
        .where((e) =>
            e.sourceText.toLowerCase().contains(lower) ||
            e.translated.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<HistoryItem?> findCached({
    required String sourceText,
    required String sourceLang,
    required String targetLang,
  }) async {
    final key = _normalize(sourceText);
    final row = await (_db.select(_db.historyEntries)
          ..where((t) =>
              t.isBookmarked.equals(true) &
              t.sourceLang.equals(sourceLang) &
              t.targetLang.equals(targetLang))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .get();
    if (row.isEmpty) return null;
    final match = row.firstWhere(
      (r) => _normalize(r.sourceText) == key,
      orElse: () => row.first,
    );
    if (_normalize(match.sourceText) != key) return null;
    return _toItem(match);
  }

  static HistoryItem _toItem(HistoryEntry row) => HistoryItem(
        id: row.id,
        sourceText: row.sourceText,
        sourceLang: row.sourceLang,
        targetLang: row.targetLang,
        translated: row.translated,
        aiResult: row.aiResult,
        isBookmarked: row.isBookmarked,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      );
}
