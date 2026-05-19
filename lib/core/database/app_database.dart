import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceText => text()();
  TextColumn get sourceLang => text()();
  TextColumn get targetLang => text()();
  TextColumn get translated => text()();
  TextColumn get aiResult => text().nullable()();
  BoolColumn get isBookmarked =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()(); // unix ms
  IntColumn get expiresAt => integer().nullable()(); // unix ms; null = forever
}

@DriftDatabase(tables: [HistoryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'speak_one',
      native: DriftNativeOptions(
        databaseDirectory: () async {
          final support = await getApplicationSupportDirectory();
          return Directory(p.join(support.path, 'db'));
        },
      ),
    );
  }
}
