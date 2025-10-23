/// データベーステーブル定義
///
/// Driftを使用した4つのテーブル（Category, Tag, Track, Daily）の定義。
///
/// 使用例:
/// ```dart
/// final db = AppDatabase();
/// final categories = await db.select(db.categories).get();
/// ```
///
/// 注意点:
/// - UUID v7をTEXT型で保存
/// - tagIdsはJSON配列として保存
/// - 日時はUTC保存
import 'package:drift/drift.dart';
import 'converter/json_converter.dart';

/// カテゴリテーブル（薬、症状、食事など）
@DataClassName('CategoryRecord')
class Categories extends Table {
  /// UUID v7形式のID
  TextColumn get id => text()();

  /// カテゴリ名（1-50文字、ユニーク）
  TextColumn get name => text()();

  /// #RRGGBB形式のカラーコード
  TextColumn get color => text()();

  /// 表示順（0始まりの連番）
  IntColumn get sortOrder => integer()();

  /// アーカイブ日時（nullなら表示中）
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// 作成日時（UTC）
  DateTimeColumn get createdAt => dateTime()();

  /// 更新日時（UTC）
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name}, // カテゴリ名はユニーク
  ];
}

/// タグテーブル（デパス、頭痛など）
@DataClassName('TagRecord')
class Tags extends Table {
  /// UUID v7形式のID
  TextColumn get id => text()();

  /// 所属カテゴリID（外部キー）
  TextColumn get categoryId => text().references(Categories, #id, onDelete: KeyAction.cascade)();

  /// タグ名（1-50文字）
  TextColumn get name => text()();

  /// カテゴリ内表示順（0始まり）
  IntColumn get sortOrder => integer()();

  /// アーカイブ日時（nullなら表示中）
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// 作成日時（UTC）
  DateTimeColumn get createdAt => dateTime()();

  /// 更新日時（UTC）
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {categoryId, name}, // カテゴリ内でタグ名はユニーク
  ];
}

/// トラックテーブル（日々の記録）
@DataClassName('TrackRecord')
class Tracks extends Table {
  /// UUID v7形式のID
  TextColumn get id => text()();

  /// メモ内容（最大1000文字、nullable）
  TextColumn get memo => text().nullable()();

  /// コンディション（-2〜2、デフォルト0）
  IntColumn get condition => integer().withDefault(const Constant(0))();

  /// タグIDのJSON配列（例: ["id1","id2"]）
  TextColumn get tagIds => text().map(const StringListConverter())();

  /// 記録日時（UTC）
  DateTimeColumn get createdAt => dateTime()();

  /// 更新日時（UTC）
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 日記テーブル（1日1件）
@DataClassName('DailyRecord')
class Dailies extends Table {
  /// 日付（YYYY-MM-DD形式、JST基準）
  TextColumn get date => text()();

  /// 日記内容（最大5000文字、nullable）
  TextColumn get memo => text().nullable()();

  /// 1日全体のコンディション（-2〜2、デフォルト0）
  IntColumn get condition => integer().withDefault(const Constant(0))();

  /// 就寝時刻（UTC、nullable）
  DateTimeColumn get sleepStart => dateTime().nullable()();

  /// 起床時刻（UTC、nullable）
  DateTimeColumn get sleepEnd => dateTime().nullable()();

  /// 作成日時（UTC）
  DateTimeColumn get createdAt => dateTime()();

  /// 更新日時（UTC）
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}
