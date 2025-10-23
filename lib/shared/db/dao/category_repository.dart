/// カテゴリリポジトリ
///
/// カテゴリの CRUD 操作を提供する。
///
/// 使用例:
/// ```dart
/// final repo = CategoryRepository(db);
/// final categories = await repo.searchCategories();
/// final newCategory = await repo.createCategory(name: '薬', color: '#3B82F6');
/// ```
///
/// 注意点:
/// - sortOrderは自動採番（既存の最大値+1）
/// - 名前の重複チェックを実施
/// - 削除時は紐づくタグもCASCADE削除される
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables.dart';
import '../../exceptions/repository_exceptions.dart';
import '../../validators/field_validators.dart';

/// カテゴリリポジトリ
class CategoryRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  CategoryRepository(this._db);

  /// カテゴリ一覧を取得
  ///
  /// パラメータ:
  /// - includeArchived: アーカイブ済みを含むか（デフォルト: false）
  ///
  /// 戻り値: sortOrderでソート済みのカテゴリリスト
  Future<List<CategoryRecord>> searchCategories({
    bool includeArchived = false,
  }) async {
    final query = _db.select(_db.categories)
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
      ]);

    if (!includeArchived) {
      query.where((t) => t.archivedAt.isNull());
    }

    return await query.get();
  }

  /// カテゴリを新規作成
  ///
  /// パラメータ:
  /// - name: カテゴリ名（1-50文字）
  /// - color: #RRGGBB形式のカラーコード
  ///
  /// 処理:
  /// - UUID v7を生成
  /// - sortOrderは既存の最大値+1を自動採番
  /// - createdAt, updatedAtに現在時刻（UTC）を設定
  ///
  /// 例外:
  /// - ValidationException: バリデーションエラー
  /// - DuplicateException: 名前重複
  Future<CategoryRecord> createCategory({
    required String name,
    required String color,
  }) async {
    // バリデーション
    final existingCategories = await searchCategories(includeArchived: true);
    final existingNames = existingCategories.map((c) => c.name).toList();

    final nameError = validateCategoryName(name, existingNames: existingNames);
    if (nameError != null) {
      if (nameError.contains('既に使用されています')) {
        throw DuplicateException(nameError, 'name');
      }
      throw ValidationException(nameError, issues: {'name': [nameError]});
    }

    final colorError = validateColor(color);
    if (colorError != null) {
      throw ValidationException(colorError, issues: {'color': [colorError]});
    }

    // sortOrderを自動採番（最大値+1）
    final maxSortOrder = existingCategories.isEmpty
        ? -1
        : existingCategories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);

    final now = DateTime.now().toUtc();
    final id = _uuid.v7();

    final companion = CategoriesCompanion.insert(
      id: id,
      name: name.trim(),
      color: color,
      sortOrder: maxSortOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.categories).insert(companion);

    // 作成したレコードを返す
    return (await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingle());
  }

  /// カテゴリを部分更新
  ///
  /// パラメータ:
  /// - id: 更新対象のカテゴリID
  /// - name: 新しいカテゴリ名（省略可）
  /// - color: 新しいカラーコード（省略可）
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
  /// - DuplicateException: 名前重複
  Future<CategoryRecord> updateCategory({
    required String id,
    String? name,
    String? color,
    bool updateArchivedAt = false,
    DateTime? archivedAt,
  }) async {
    // 存在チェック
    final existing = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw NotFoundException('カテゴリが見つかりません: $id');
    }

    // バリデーション
    if (name != null) {
      final existingCategories = await searchCategories(includeArchived: true);
      final existingNames = existingCategories.where((c) => c.id != id).map((c) => c.name).toList();

      final nameError = validateCategoryName(
        name,
        existingNames: existingNames,
        currentName: existing.name,
      );
      if (nameError != null) {
        if (nameError.contains('既に使用されています')) {
          throw DuplicateException(nameError, 'name');
        }
        throw ValidationException(nameError, issues: {'name': [nameError]});
      }
    }

    if (color != null) {
      final colorError = validateColor(color);
      if (colorError != null) {
        throw ValidationException(colorError, issues: {'color': [colorError]});
      }
    }

    // 更新内容を構築
    final companion = CategoriesCompanion(
      name: name != null ? Value(name.trim()) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
      archivedAt: updateArchivedAt ? Value(archivedAt) : const Value.absent(),
      updatedAt: Value(DateTime.now().toUtc()),
    );

    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(companion);

    // 更新後のレコードを返す
    return (await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingle());
  }

  /// カテゴリの表示順を一括更新
  ///
  /// パラメータ:
  /// - items: IDと新しいsortOrderのリスト
  ///
  /// 制約:
  /// - items.lengthが全カテゴリ数と一致
  /// - sortOrderが0からの連番（0, 1, 2, ...）
  ///
  /// 例外:
  /// - ValidationException: 制約違反
  /// - NotFoundException: 指定IDが存在しない
  Future<void> reorderCategories(
    List<({String id, int sortOrder})> items,
  ) async {
    final allCategories = await searchCategories(includeArchived: true);

    // バリデーション
    final reorderError = validateReorder(
      items: items,
      expectedCount: allCategories.length,
    );
    if (reorderError != null) {
      throw ValidationException(reorderError);
    }

    // 存在チェック
    final existingIds = allCategories.map((c) => c.id).toSet();
    for (final item in items) {
      if (!existingIds.contains(item.id)) {
        throw NotFoundException('指定されたIDが存在しません: ${item.id}');
      }
    }

    // トランザクションで一括更新
    await _db.transaction(() async {
      for (final item in items) {
        final companion = CategoriesCompanion(
          sortOrder: Value(item.sortOrder),
          updatedAt: Value(DateTime.now().toUtc()),
        );
        await (_db.update(_db.categories)..where((t) => t.id.equals(item.id))).write(companion);
      }
    });
  }

  /// カテゴリを削除
  ///
  /// パラメータ:
  /// - id: 削除対象のカテゴリID
  ///
  /// 処理:
  /// - カテゴリ削除時、紐づくタグはCASCADE削除される
  ///
  /// 例外:
  /// - NotFoundException: IDが存在しない
  Future<void> deleteCategory(String id) async {
    final count = await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
    if (count == 0) {
      throw NotFoundException('カテゴリが見つかりません: $id');
    }
  }
}
