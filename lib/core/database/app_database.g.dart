// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this, prefer_const_constructors_in_immutables, prefer_const_constructors, unnecessary_import, invalid_annotation_target

class HistoryEntry extends DataClass implements Insertable<HistoryEntry> {
  final int id;
  final String sourceText;
  final String sourceLang;
  final String targetLang;
  final String translated;
  final String? aiResult;
  final bool isBookmarked;
  final int createdAt;
  final int? expiresAt;
  const HistoryEntry({
    required this.id,
    required this.sourceText,
    required this.sourceLang,
    required this.targetLang,
    required this.translated,
    this.aiResult,
    required this.isBookmarked,
    required this.createdAt,
    this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_text'] = Variable<String>(sourceText);
    map['source_lang'] = Variable<String>(sourceLang);
    map['target_lang'] = Variable<String>(targetLang);
    map['translated'] = Variable<String>(translated);
    if (!nullToAbsent || aiResult != null) {
      map['ai_result'] = Variable<String>(aiResult);
    }
    map['is_bookmarked'] = Variable<bool>(isBookmarked);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    return map;
  }

  HistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return HistoryEntriesCompanion(
      id: Value(id),
      sourceText: Value(sourceText),
      sourceLang: Value(sourceLang),
      targetLang: Value(targetLang),
      translated: Value(translated),
      aiResult: aiResult == null && nullToAbsent
          ? const Value.absent()
          : Value(aiResult),
      isBookmarked: Value(isBookmarked),
      createdAt: Value(createdAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      sourceText: serializer.fromJson<String>(json['source_text']),
      sourceLang: serializer.fromJson<String>(json['source_lang']),
      targetLang: serializer.fromJson<String>(json['target_lang']),
      translated: serializer.fromJson<String>(json['translated']),
      aiResult: serializer.fromJson<String?>(json['ai_result']),
      isBookmarked: serializer.fromJson<bool>(json['is_bookmarked']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      expiresAt: serializer.fromJson<int?>(json['expires_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source_text': serializer.toJson<String>(sourceText),
      'source_lang': serializer.toJson<String>(sourceLang),
      'target_lang': serializer.toJson<String>(targetLang),
      'translated': serializer.toJson<String>(translated),
      'ai_result': serializer.toJson<String?>(aiResult),
      'is_bookmarked': serializer.toJson<bool>(isBookmarked),
      'created_at': serializer.toJson<int>(createdAt),
      'expires_at': serializer.toJson<int?>(expiresAt),
    };
  }

  HistoryEntry copyWith(
          {int? id,
          String? sourceText,
          String? sourceLang,
          String? targetLang,
          String? translated,
          Value<String?> aiResult = const Value.absent(),
          bool? isBookmarked,
          int? createdAt,
          Value<int?> expiresAt = const Value.absent()}) =>
      HistoryEntry(
        id: id ?? this.id,
        sourceText: sourceText ?? this.sourceText,
        sourceLang: sourceLang ?? this.sourceLang,
        targetLang: targetLang ?? this.targetLang,
        translated: translated ?? this.translated,
        aiResult: aiResult.present ? aiResult.value : this.aiResult,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
      );
  @override
  String toString() {
    return (StringBuffer('HistoryEntry(')
          ..write('id: $id, ')
          ..write('sourceText: $sourceText, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('targetLang: $targetLang, ')
          ..write('translated: $translated, ')
          ..write('aiResult: $aiResult, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceText, sourceLang, targetLang,
      translated, aiResult, isBookmarked, createdAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryEntry &&
          other.id == this.id &&
          other.sourceText == this.sourceText &&
          other.sourceLang == this.sourceLang &&
          other.targetLang == this.targetLang &&
          other.translated == this.translated &&
          other.aiResult == this.aiResult &&
          other.isBookmarked == this.isBookmarked &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class HistoryEntriesCompanion extends UpdateCompanion<HistoryEntry> {
  final Value<int> id;
  final Value<String> sourceText;
  final Value<String> sourceLang;
  final Value<String> targetLang;
  final Value<String> translated;
  final Value<String?> aiResult;
  final Value<bool> isBookmarked;
  final Value<int> createdAt;
  final Value<int?> expiresAt;
  const HistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.sourceLang = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.translated = const Value.absent(),
    this.aiResult = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
  });
  HistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String sourceText,
    required String sourceLang,
    required String targetLang,
    required String translated,
    this.aiResult = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    required int createdAt,
    this.expiresAt = const Value.absent(),
  })  : sourceText = Value(sourceText),
        sourceLang = Value(sourceLang),
        targetLang = Value(targetLang),
        translated = Value(translated),
        createdAt = Value(createdAt);
  static Insertable<HistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? sourceText,
    Expression<String>? sourceLang,
    Expression<String>? targetLang,
    Expression<String>? translated,
    Expression<String>? aiResult,
    Expression<bool>? isBookmarked,
    Expression<int>? createdAt,
    Expression<int>? expiresAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceText != null) 'source_text': sourceText,
      if (sourceLang != null) 'source_lang': sourceLang,
      if (targetLang != null) 'target_lang': targetLang,
      if (translated != null) 'translated': translated,
      if (aiResult != null) 'ai_result': aiResult,
      if (isBookmarked != null) 'is_bookmarked': isBookmarked,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
  }

  HistoryEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? sourceText,
      Value<String>? sourceLang,
      Value<String>? targetLang,
      Value<String>? translated,
      Value<String?>? aiResult,
      Value<bool>? isBookmarked,
      Value<int>? createdAt,
      Value<int?>? expiresAt}) {
    return HistoryEntriesCompanion(
      id: id ?? this.id,
      sourceText: sourceText ?? this.sourceText,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      translated: translated ?? this.translated,
      aiResult: aiResult ?? this.aiResult,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (sourceLang.present) {
      map['source_lang'] = Variable<String>(sourceLang.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (translated.present) {
      map['translated'] = Variable<String>(translated.value);
    }
    if (aiResult.present) {
      map['ai_result'] = Variable<String>(aiResult.value);
    }
    if (isBookmarked.present) {
      map['is_bookmarked'] = Variable<bool>(isBookmarked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sourceText: $sourceText, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('targetLang: $targetLang, ')
          ..write('translated: $translated, ')
          ..write('aiResult: $aiResult, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }
}

class $HistoryEntriesTable extends HistoryEntries
    with TableInfo<$HistoryEntriesTable, HistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourceTextMeta =
      const VerificationMeta('sourceText');
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
      'source_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceLangMeta =
      const VerificationMeta('sourceLang');
  @override
  late final GeneratedColumn<String> sourceLang = GeneratedColumn<String>(
      'source_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetLangMeta =
      const VerificationMeta('targetLang');
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
      'target_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _translatedMeta =
      const VerificationMeta('translated');
  @override
  late final GeneratedColumn<String> translated = GeneratedColumn<String>(
      'translated', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aiResultMeta =
      const VerificationMeta('aiResult');
  @override
  late final GeneratedColumn<String> aiResult = GeneratedColumn<String>(
      'ai_result', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isBookmarkedMeta =
      const VerificationMeta('isBookmarked');
  @override
  late final GeneratedColumn<bool> isBookmarked = GeneratedColumn<bool>(
      'is_bookmarked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_bookmarked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourceText,
        sourceLang,
        targetLang,
        translated,
        aiResult,
        isBookmarked,
        createdAt,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_entries';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_text')) {
      context.handle(_sourceTextMeta,
          sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta));
    } else if (isInserting) {
      context.missing(_sourceTextMeta);
    }
    if (data.containsKey('source_lang')) {
      context.handle(_sourceLangMeta,
          sourceLang.isAcceptableOrUnknown(data['source_lang']!, _sourceLangMeta));
    } else if (isInserting) {
      context.missing(_sourceLangMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(_targetLangMeta,
          targetLang.isAcceptableOrUnknown(data['target_lang']!, _targetLangMeta));
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('translated')) {
      context.handle(_translatedMeta,
          translated.isAcceptableOrUnknown(data['translated']!, _translatedMeta));
    } else if (isInserting) {
      context.missing(_translatedMeta);
    }
    if (data.containsKey('ai_result')) {
      context.handle(_aiResultMeta,
          aiResult.isAcceptableOrUnknown(data['ai_result']!, _aiResultMeta));
    }
    if (data.containsKey('is_bookmarked')) {
      context.handle(_isBookmarkedMeta,
          isBookmarked.isAcceptableOrUnknown(data['is_bookmarked']!, _isBookmarkedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourceText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_text'])!,
      sourceLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_lang'])!,
      targetLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_lang'])!,
      translated: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}translated'])!,
      aiResult: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_result']),
      isBookmarked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_bookmarked'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at']),
    );
  }

  @override
  $HistoryEntriesTable createAlias(String alias) {
    return $HistoryEntriesTable(attachedDatabase, alias);
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $HistoryEntriesTable historyEntries =
      $HistoryEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [historyEntries];
}
