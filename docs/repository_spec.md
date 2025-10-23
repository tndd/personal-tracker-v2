# Repository仕様

各データ層の操作インターフェース定義。

---

## CategoryRepository

### searchCategories

カテゴリ一覧を取得。

```dart
Future<List<CategoryRecord>> searchCategories({
  bool includeArchived = false,
});
```

**パラメータ:**
- `includeArchived`: アーカイブ済みを含むか（デフォルト: false）

**戻り値:**
- `sortOrder` でソート済みのカテゴリリスト

**例:**
```dart
// 表示中のカテゴリのみ
final categories = await repo.searchCategories();

// アーカイブ済みを含む全て
final allCategories = await repo.searchCategories(includeArchived: true);
```

---

### createCategory

カテゴリを新規作成。

```dart
Future<CategoryRecord> createCategory({
  required String name,
  required String color,
});
```

**パラメータ:**
- `name`: カテゴリ名（1-50文字）
- `color`: #RRGGBB形式のカラーコード

**処理:**
- UUID v7を生成
- `sortOrder` は既存の最大値 + 1 を自動採番
- `createdAt`, `updatedAt` に現在時刻（UTC）を設定

**例外:**
- バリデーションエラー: `ValidationException`
- 名前重複: `DuplicateException`

**例:**
```dart
final category = await repo.createCategory(
  name: '服薬',
  color: '#3B82F6',
);
```

---

### updateCategory

カテゴリを部分更新。

```dart
Future<CategoryRecord> updateCategory({
  required String id,
  String? name,
  String? color,
  bool updateArchivedAt = false,
  DateTime? archivedAt,
});
```

**パラメータ:**
- `id`: 更新対象のカテゴリID
- `name`: 新しいカテゴリ名（省略可）
- `color`: 新しいカラーコード（省略可）
- `updateArchivedAt`: `archivedAt` を更新するか
- `archivedAt`: アーカイブ日時（nullで解除）

**処理:**
- `updatedAt` を現在時刻に更新
- 指定されたフィールドのみ更新

**例外:**
- IDが存在しない: `NotFoundException`
- バリデーションエラー: `ValidationException`

**例:**
```dart
// 名前と色を変更
await repo.updateCategory(
  id: categoryId,
  name: '食習慣',
  color: '#10B981',
);

// アーカイブ
await repo.updateCategory(
  id: categoryId,
  updateArchivedAt: true,
  archivedAt: DateTime.now().toUtc(),
);

// アーカイブ解除
await repo.updateCategory(
  id: categoryId,
  updateArchivedAt: true,
  archivedAt: null,
);
```

---

### reorderCategories

カテゴリの表示順を一括更新。

```dart
Future<void> reorderCategories(
  List<({String id, int sortOrder})> items,
);
```

**パラメータ:**
- `items`: ID と新しい sortOrder のリスト

**制約:**
- `items.length` が全カテゴリ数と一致
- `sortOrder` が 0 からの連番（0, 1, 2, ...）

**例外:**
- 制約違反: `ValidationException`

**例:**
```dart
await repo.reorderCategories([
  (id: 'id-3', sortOrder: 0),
  (id: 'id-1', sortOrder: 1),
  (id: 'id-2', sortOrder: 2),
]);
```

---

## TagRepository

### searchTags

タグ一覧を取得。

```dart
Future<List<TagRecord>> searchTags({
  required String categoryId,
  bool includeArchived = false,
});
```

**パラメータ:**
- `categoryId`: 対象カテゴリID
- `includeArchived`: アーカイブ済みを含むか

**戻り値:**
- 指定カテゴリ内のタグリスト（`sortOrder` でソート済み）

---

### createTag

タグを新規作成。

```dart
Future<TagRecord> createTag({
  required String categoryId,
  required String name,
});
```

**パラメータ:**
- `categoryId`: 所属カテゴリID
- `name`: タグ名（1-50文字）

**処理:**
- UUID v7を生成
- `sortOrder` はカテゴリ内の最大値 + 1 を自動採番
- `createdAt`, `updatedAt` に現在時刻を設定

**例外:**
- カテゴリ内で名前重複: `DuplicateException`
- カテゴリIDが存在しない: `NotFoundException`

---

### updateTag

タグを部分更新。

```dart
Future<TagRecord> updateTag({
  required String id,
  String? name,
  bool updateArchivedAt = false,
  DateTime? archivedAt,
});
```

カテゴリの `updateCategory` と同様の仕様。

---

### reorderTags

タグの表示順を一括更新。

```dart
Future<void> reorderTags({
  required String categoryId,
  required List<({String id, int sortOrder})> items,
});
```

**制約:**
- `items.length` が対象カテゴリ内のタグ数と一致
- `sortOrder` が 0 からの連番

---

### deleteTag

タグを削除（アーカイブ画面でのみ実行可能）。

```dart
Future<void> deleteTag(String id);
```

**処理:**
1. 指定されたタグをTagsテーブルから削除
2. **全Trackの `tagIds` から該当IDを即座にクリーンアップ**
   - 全Trackをスキャンし、削除されたタグIDを配列から除外
   - `updatedAt` を更新

**例:**
```dart
// タグ削除
await tagRepo.deleteTag('tag-id-123');

// 削除後、全Trackの tagIds から 'tag-id-123' が自動的に除外される
```

---

## TrackRepository

### searchTracks

トラック一覧を取得（ページング対応）。

```dart
Future<List<TrackRecord>> searchTracks({
  int limit = 50,
  DateTime? before,
  String? memoKeyword,
  List<String>? tagIds,
  int? condition,
});
```

**パラメータ:**
- `limit`: 取得件数（デフォルト: 50）
- `before`: この日時より前のレコードを取得（ページング用、`recordedAt` 基準）
- `memoKeyword`: メモの部分一致検索
- `tagIds`: タグIDでフィルタ（OR条件）
- `condition`: コンディションでフィルタ

**戻り値:**
- `recordedAt` の降順でソート済みのトラックリスト

**例:**
```dart
// 最新50件
final tracks = await repo.searchTracks(limit: 50);

// 過去を遡る（ページング）
final older = await repo.searchTracks(
  limit: 50,
  before: tracks.last.recordedAt,
);

// タグでフィルタ
final filtered = await repo.searchTracks(
  tagIds: ['tag-id-1', 'tag-id-2'],
);
```

---

### createTrack

トラックを新規作成。

```dart
Future<TrackRecord> createTrack({
  String? memo,
  int condition = 0,
  List<String> tagIds = const [],
  DateTime? recordedAt,
});
```

**パラメータ:**
- `memo`: メモ（最大1000文字、省略可）
- `condition`: コンディション（-2〜2、デフォルト: 0）
- `tagIds`: タグIDリスト
- `recordedAt`: 記録日時（省略時は現在時刻）

**処理:**
- UUID v7を生成
- `recordedAt` をパラメータまたは現在時刻に設定
- `createdAt`, `updatedAt` に現在時刻を設定
- 存在しないタグIDは除外して保存

---

### updateTrack

トラックを更新。

```dart
Future<TrackRecord> updateTrack({
  required String id,
  String? memo,
  int? condition,
  List<String>? tagIds,
  DateTime? recordedAt,
});
```

**パラメータ:**
- `id`: 更新対象のトラックID
- `memo`: 新しいメモ（省略可）
- `condition`: 新しいコンディション（省略可）
- `tagIds`: 新しいタグIDリスト（省略可）
- `recordedAt`: 新しい記録日時（省略可、過去日時への変更可能）

**処理:**
- `updatedAt` を現在時刻に更新
- 指定されたフィールドのみ更新
- 存在しないタグIDは除外して保存

---

### deleteTrack

トラックを削除。

```dart
Future<void> deleteTrack(String id);
```

---

## DailyRepository

### findDaily

指定日付の日記を取得。

```dart
Future<DailyRecord?> findDaily(String date);
```

**パラメータ:**
- `date`: YYYY-MM-DD形式の日付

**戻り値:**
- 日記レコード（存在しない場合は null）

---

### searchDailies

日記一覧を取得（期間指定）。

```dart
Future<List<DailyRecord>> searchDailies({
  String? startDate,
  String? endDate,
  int? condition,
});
```

**パラメータ:**
- `startDate`: 開始日（YYYY-MM-DD）
- `endDate`: 終了日（YYYY-MM-DD）
- `condition`: コンディションでフィルタ

**戻り値:**
- 日付の降順でソート済みの日記リスト

---

### upsertDaily

日記を作成または更新。

```dart
Future<DailyRecord> upsertDaily({
  required String date,
  String? memo,
  int condition = 0,
  DateTime? sleepStart,
  DateTime? sleepEnd,
});
```

**処理:**
- 指定日付の日記が存在すれば更新、なければ作成
- `updatedAt` を現在時刻に更新

---

### deleteDaily

日記を削除。

```dart
Future<void> deleteDaily(String date);
```

---

## 例外定義

```dart
// バリデーションエラー
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? issues;
}

// リソース未存在
class NotFoundException implements Exception {
  final String message;
}

// 重複エラー
class DuplicateException implements Exception {
  final String message;
  final String field;
}
```
