/// タグリポジトリ
///
/// タグの CRUD 操作を提供する。
///
/// 使用例:
/// ```dart
/// final repo = TagRepository(db);
/// final tags = await repo.searchTags(categoryId: 'category-id');
/// final newTag = await repo.createTag(categoryId: 'category-id', name: 'デパス');
/// ```
///
/// 注意点:
/// - sortOrderはカテゴリ内で自動採番
/// - カテゴリ内でタグ名の重複チェックを実施
/// - カテゴリ削除時はCASCADE削除される
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables.dart';
import '../../exceptions/repository_exceptions.dart';
import '../../validators/field_validators.dart';

/// タグリポジトリ
class TagRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  TagRepository(this._db);

  /// タグ一覧を取得
  ///
  /// パラメータ:
  /// - categoryId: 対象カテゴリID
  /// - includeArchived: アーカイブ済みを含むか（デフォルト: false）
  ///
  /// 戻り値: 指定カテゴリ内のタグリスト（sortOrderでソート済み）
  Future<List<TagRecord>> searchTags({
    required String categoryId,
    bool includeArchived = false,
  }) async {
    final query = _db.select(_db.tags)
      ..where((t) => t.categoryId.equals(categoryId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
      ]);

    if (!includeArchived) {
      query.where((t) => t.archivedAt.isNull());
    }

    return await query.get();
  }

  /// タグを新規作成
  ///
  /// パラメータ:
  /// - categoryId: 所属カテゴリID
  /// - name: タグ名（1-50文字）
  ///
  /// 処理:
  /// - UUID v7を生成
  /// - sortOrderはカテゴリ内の最大値+1を自動採番
  /// - createdAt, updatedAtに現在時刻（UTC）を設定
  ///
  /// 例外:
  /// - ValidationException: バリデーションエラー
  /// - DuplicateException: カテゴリ内で名前重複
  /// - NotFoundException: カテゴリIDが存在しない
  Future<TagRecord> createTag({
    required String categoryId,
    required String name,
  }) async {
    // カテゴリ存在チェック
    final category = await (_db.select(_db.categories)
      ..where((t) => t.id.equals(categoryId))).getSingleOrNull();
    if (category == null) {
      throw NotFoundException('カテゴリが見つかりません: $categoryId');
    }

    // バリデーション
    final existingTags = await searchTags(categoryId: categoryId, includeArchived: true);
    final existingNames = existingTags.map((t) => t.name).toList();

    final nameError = validateTagName(name, existingNamesInCategory: existingNames);
    if (nameError != null) {
      if (nameError.contains('既に使用されています')) {
        throw DuplicateException(nameError, 'name');
      }
      throw ValidationException(nameError, issues: {'name': [nameError]});
    }

    // sortOrderを自動採番（カテゴリ内の最大値+1）
    final maxSortOrder = existingTags.isEmpty
        ? -1
        : existingTags.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b);

    final now = DateTime.now().toUtc();
    final id = _uuid.v7();

    final companion = TagsCompanion.insert(
      id: id,
      categoryId: categoryId,
      name: name.trim(),
      sortOrder: maxSortOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.tags).insert(companion);

    // 作成したレコードを返す
    return (await (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingle());
  }

  /// タグを部分更新
  ///
  /// パラメータ:
  /// - id: 更新対象のタグID
  /// - name: 新しいタグ名（省略可）
  /// - updateArchivedAt: archivedAtを更新するか
  /// - archivedAt: アーカイブ日時（nullで解除）
  ///
  /// 処理:
  /// - updatedAtを現在時刻に更新
  /// - 指定されたフィールドのみ更新
  ///
  /// 例外:
  /// - NotFoundException: IDが存在しない
  /// - ValidationException: バリデーションエラー
  /// - DuplicateException: カテゴリ内で名前重複
  Future<TagRecord> updateTag({
    required String id,
    String? name,
    bool updateArchivedAt = false,
    DateTime? archivedAt,
  }) async {
    // 存在チェック
    final existing = await (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw NotFoundException('タグが見つかりません: $id');
    }

    // バリデーション
    if (name != null) {
      final existingTags = await searchTags(
        categoryId: existing.categoryId,
        includeArchived: true,
      );
      final existingNames = existingTags.where((t) => t.id != id).map((t) => t.name).toList();

      final nameError = validateTagName(
        name,
        existingNamesInCategory: existingNames,
        currentName: existing.name,
      );
      if (nameError != null) {
        if (nameError.contains('既に使用されています')) {
          throw DuplicateException(nameError, 'name');
        }
        throw ValidationException(nameError, issues: {'name': [nameError]});
      }
    }

    // 更新内容を構築
    final companion = TagsCompanion(
      name: name != null ? Value(name.trim()) : const Value.absent(),
      archivedAt: updateArchivedAt ? Value(archivedAt) : const Value.absent(),
      updatedAt: Value(DateTime.now().toUtc()),
    );

    await (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(companion);

    // 更新後のレコードを返す
    return (await (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingle());
  }

  /// タグの表示順を一括更新
  ///
  /// パラメータ:
  /// - categoryId: 対象カテゴリID
  /// - items: IDと新しいsortOrderのリスト
  ///
  /// 制約:
  /// - items.lengthが対象カテゴリ内のタグ数と一致
  /// - sortOrderが0からの連番
  ///
  /// 例外:
  /// - ValidationException: 制約違反
  /// - NotFoundException: 指定IDが存在しない
  Future<void> reorderTags({
    required String categoryId,
    required List<({String id, int sortOrder})> items,
  }) async {
    final allTags = await searchTags(categoryId: categoryId, includeArchived: true);

    // バリデーション
    final reorderError = validateReorder(
      items: items,
      expectedCount: allTags.length,
    );
    if (reorderError != null) {
      throw ValidationException(reorderError);
    }

    // 存在チェック
    final existingIds = allTags.map((t) => t.id).toSet();
    for (final item in items) {
      if (!existingIds.contains(item.id)) {
        throw NotFoundException('指定されたIDが存在しません: ${item.id}');
      }
    }

    // トランザクションで一括更新
    await _db.transaction(() async {
      for (final item in items) {
        final companion = TagsCompanion(
          sortOrder: Value(item.sortOrder),
          updatedAt: Value(DateTime.now().toUtc()),
        );
        await (_db.update(_db.tags)..where((t) => t.id.equals(item.id))).write(companion);
      }
    });
  }

  /// タグを削除（アーカイブ画面でのみ実行可能）
  ///
  /// パラメータ:
  /// - id: 削除対象のタグID
  ///
  /// 処理:
  /// 1. 指定されたタグをTagsテーブルから削除
  /// 2. 全Trackの tagIds から該当IDを即座にクリーンアップ
  ///
  /// 例外:
  /// - NotFoundException: IDが存在しない
  Future<void> deleteTag(String id) async {
    // トランザクション内で削除とクリーンアップを実行
    await _db.transaction(() async {
      // 1. タグを削除
      final count = await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
      if (count == 0) {
        throw NotFoundException('タグが見つかりません: $id');
      }

      // 2. 全Trackの tagIds から該当IDをクリーンアップ
      final allTracks = await (_db.select(_db.tracks)).get();
      for (final track in allTracks) {
        if (track.tagIds.contains(id)) {
          final newTagIds = track.tagIds.where((tagId) => tagId != id).toList();
          await (_db.update(_db.tracks)..where((t) => t.id.equals(track.id))).write(
            TracksCompanion(
              tagIds: Value(newTagIds),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      }
    });
  }
}
