# データベーススキーマ定義

Flutter + Drift（SQLite）のスキーマ定義。

## 共通仕様

- **ID**: UUID v7形式（TEXT型として保存）
- **日時**: `DateTime`型、UTC保存・JST表示
- **updated_at**: アプリケーション側で更新時に自動設定

---

## Category テーブル

カテゴリ情報（薬、症状、食事など）。

```dart
@DataClassName('CategoryRecord')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### フィールド

| フィールド | Dart型 | 制約 | 説明 |
|-----------|--------|------|------|
| `id` | String | PRIMARY KEY | UUID v7 |
| `name` | String | NOT NULL, UNIQUE | カテゴリ名 |
| `color` | String | NOT NULL | #RRGGBB形式 |
| `sortOrder` | int | NOT NULL | 表示順（0始まり連番） |
| `archivedAt` | DateTime? | NULLABLE | アーカイブ日時（null=表示中） |
| `createdAt` | DateTime | NOT NULL | 作成日時（UTC） |
| `updatedAt` | DateTime | NOT NULL | 更新日時（UTC） |

### 整合条件

- `sortOrder` は全カテゴリで重複しない連番（0, 1, 2, ...）を維持
- `name` は全カテゴリで一意
- `color` は正規表現 `^#[0-9A-Fa-f]{6}$` に適合

### 削除時の挙動

- カテゴリ削除時、紐づくタグはCASCADE削除される

---

## Tag テーブル

タグ情報（デパス、頭痛など）。

```dart
@DataClassName('TagRecord')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### フィールド

| フィールド | Dart型 | 制約 | 説明 |
|-----------|--------|------|------|
| `id` | String | PRIMARY KEY | UUID v7 |
| `categoryId` | String | NOT NULL, FOREIGN KEY | 所属カテゴリID |
| `name` | String | NOT NULL | タグ名 |
| `sortOrder` | int | NOT NULL | カテゴリ内表示順（0始まり） |
| `archivedAt` | DateTime? | NULLABLE | アーカイブ日時 |
| `createdAt` | DateTime | NOT NULL | 作成日時（UTC） |
| `updatedAt` | DateTime | NOT NULL | 更新日時（UTC） |

### 整合条件

- `sortOrder` は各カテゴリ内で重複しない連番を維持
- `(categoryId, name)` の組み合わせは一意（カテゴリ内でタグ名重複禁止）
- `categoryId` は外部キー（ON DELETE CASCADE）

---

## Track テーブル

日々の記録（メモ、コンディション、タグ）。

```dart
@DataClassName('TrackRecord')
class Tracks extends Table {
  TextColumn get id => text()();
  TextColumn get memo => text().nullable()();
  IntColumn get condition => integer().withDefault(const Constant(0))();
  TextColumn get tagIds => text()(); // JSON配列として保存
  DateTimeColumn get recordedAt => dateTime()(); // 記録日時（ユーザー指定可能）
  DateTimeColumn get createdAt => dateTime()(); // 作成日時（自動設定）
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### フィールド

| フィールド | Dart型 | SQLite型 | 説明 |
|-----------|--------|---------|------|
| `id` | String | TEXT | UUID v7 |
| `memo` | String? | TEXT | メモ内容（最大1000文字） |
| `condition` | int | INTEGER | コンディション（-2〜2、デフォルト0） |
| `tagIds` | List\<String\> | TEXT | タグIDのJSON配列 |
| `recordedAt` | DateTime | INTEGER | 記録日時（UTC、ユーザーが記録した時刻） |
| `createdAt` | DateTime | INTEGER | 作成日時（UTC、レコード作成時に自動設定） |
| `updatedAt` | DateTime | INTEGER | 更新日時（UTC） |

### 補足仕様

- `tagIds` に存在しないタグIDが含まれていても**エラーにせず無視**する（削除済みタグは非表示）
- `tagIds` は内部的にJSON文字列 `["id1","id2"]` として保存
- `recordedAt` がトラックの記録日時（過去日時の設定可能、デフォルトは現在時刻）
- `createdAt` はレコード作成時に自動設定（編集不可）
- 時系列表示やページングは `recordedAt` を基準とする

---

## Daily テーブル

日記（1日1件）。

```dart
@DataClassName('DailyRecord')
class Dailies extends Table {
  TextColumn get date => text()(); // YYYY-MM-DD形式
  TextColumn get memo => text().nullable()();
  IntColumn get condition => integer().withDefault(const Constant(0))();
  DateTimeColumn get sleepStart => dateTime().nullable()();
  DateTimeColumn get sleepEnd => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}
```

### フィールド

| フィールド | Dart型 | 制約 | 説明 |
|-----------|--------|------|------|
| `date` | String | PRIMARY KEY | 日付（YYYY-MM-DD形式） |
| `memo` | String? | NULLABLE | 日記内容（最大5000文字） |
| `condition` | int | NOT NULL | 1日全体のコンディション（-2〜2） |
| `sleepStart` | DateTime? | NULLABLE | 就寝時刻（UTC） |
| `sleepEnd` | DateTime? | NULLABLE | 起床時刻（UTC） |
| `createdAt` | DateTime | NOT NULL | 作成日時（UTC） |
| `updatedAt` | DateTime | NOT NULL | 更新日時（UTC） |

### 補足仕様

- `date` は JST基準の日付文字列（例: "2025-10-23"）
- 睡眠時間の計算は `sleepEnd - sleepStart` で行う
- 日付が変わっても睡眠記録が日をまたぐ場合は `sleepStart` の日付に記録

---

## インデックス

実装時に以下のインデックスを作成すること：

```dart
// CategoryのsortOrder検索用
@TableIndex(name: 'category_sort_order_idx', columns: {#sortOrder})

// Tagのカテゴリ別検索用
@TableIndex(name: 'tag_category_id_idx', columns: {#categoryId})

// Trackの時系列検索用（記録日時でソート）
@TableIndex(name: 'track_recorded_at_idx', columns: {#recordedAt})
```
