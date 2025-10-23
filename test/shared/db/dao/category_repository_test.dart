/// CategoryRepositoryのユニットテスト
///
/// 検証価値の高い項目のみテスト:
/// - 作成時のsortOrder自動採番
/// - 名前重複検証
/// - 更新時の部分更新
/// - 並び替えの連番制約
/// - アーカイブフィルター
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';
import 'package:personal_tracker_v2/shared/db/dao/category_repository.dart';
import 'package:personal_tracker_v2/shared/exceptions/repository_exceptions.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = CategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepository', () {
    test('searchCategories は sortOrder でソートされたリストを返す', () async {
      await repo.createCategory(name: '症状', color: '#EF4444');
      await repo.createCategory(name: '薬', color: '#3B82F6');
      await repo.createCategory(name: '食事', color: '#10B981');

      final categories = await repo.searchCategories();

      expect(categories.length, 3);
      expect(categories[0].name, '症状');
      expect(categories[0].sortOrder, 0);
      expect(categories[1].name, '薬');
      expect(categories[1].sortOrder, 1);
      expect(categories[2].name, '食事');
      expect(categories[2].sortOrder, 2);
    });

    test('searchCategories はアーカイブ済みを除外する', () async {
      final cat1 = await repo.createCategory(name: '症状', color: '#EF4444');
      await repo.createCategory(name: '薬', color: '#3B82F6');

      // cat1をアーカイブ
      await repo.updateCategory(
        id: cat1.id,
        updateArchivedAt: true,
        archivedAt: DateTime.now().toUtc(),
      );

      final categories = await repo.searchCategories();
      expect(categories.length, 1);
      expect(categories[0].name, '薬');

      final allCategories = await repo.searchCategories(includeArchived: true);
      expect(allCategories.length, 2);
    });

    test('createCategory は sortOrder を自動採番する', () async {
      final cat1 = await repo.createCategory(name: '薬', color: '#3B82F6');
      final cat2 = await repo.createCategory(name: '症状', color: '#EF4444');

      expect(cat1.sortOrder, 0);
      expect(cat2.sortOrder, 1);
    });

    test('createCategory は名前重複時に DuplicateException をスローする', () async {
      await repo.createCategory(name: '薬', color: '#3B82F6');

      expect(
        () => repo.createCategory(name: '薬', color: '#EF4444'),
        throwsA(isA<DuplicateException>()),
      );
    });

    test('createCategory は空文字時に ValidationException をスローする', () async {
      expect(
        () => repo.createCategory(name: '', color: '#3B82F6'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createCategory は51文字以上で ValidationException をスローする', () async {
      final longName = 'a' * 51;

      expect(
        () => repo.createCategory(name: longName, color: '#3B82F6'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createCategory は不正なカラーコードで ValidationException をスローする', () async {
      expect(
        () => repo.createCategory(name: '薬', color: 'invalid'),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => repo.createCategory(name: '薬', color: '#GGGGGG'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('updateCategory は名前と色を更新する', () async {
      final cat = await repo.createCategory(name: '薬', color: '#3B82F6');

      final updated = await repo.updateCategory(
        id: cat.id,
        name: '服薬',
        color: '#F59E0B',
      );

      expect(updated.name, '服薬');
      expect(updated.color, '#F59E0B');
      expect(updated.sortOrder, 0); // sortOrderは変わらない
    });

    test('updateCategory は存在しないIDで NotFoundException をスローする', () async {
      expect(
        () => repo.updateCategory(id: 'nonexistent', name: 'test'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('updateCategory はアーカイブ状態を更新する', () async {
      final cat = await repo.createCategory(name: '薬', color: '#3B82F6');

      // アーカイブ
      final archived = await repo.updateCategory(
        id: cat.id,
        updateArchivedAt: true,
        archivedAt: DateTime.now().toUtc(),
      );
      expect(archived.archivedAt, isNotNull);

      // アーカイブ解除
      final unarchived = await repo.updateCategory(
        id: cat.id,
        updateArchivedAt: true,
        archivedAt: null,
      );
      expect(unarchived.archivedAt, isNull);
    });

    test('reorderCategories は表示順を一括更新する', () async {
      final cat1 = await repo.createCategory(name: '薬', color: '#3B82F6');
      final cat2 = await repo.createCategory(name: '症状', color: '#EF4444');
      final cat3 = await repo.createCategory(name: '食事', color: '#10B981');

      // 順番を逆転
      await repo.reorderCategories([
        (id: cat3.id, sortOrder: 0),
        (id: cat2.id, sortOrder: 1),
        (id: cat1.id, sortOrder: 2),
      ]);

      final categories = await repo.searchCategories();
      expect(categories[0].name, '食事');
      expect(categories[1].name, '症状');
      expect(categories[2].name, '薬');
    });

    test('reorderCategories は不正な件数で ValidationException をスローする', () async {
      final cat1 = await repo.createCategory(name: '薬', color: '#3B82F6');
      await repo.createCategory(name: '症状', color: '#EF4444');

      expect(
        () => repo.reorderCategories([
          (id: cat1.id, sortOrder: 0),
          // 1件足りない
        ]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('reorderCategories は連番でない sortOrder で ValidationException をスローする', () async {
      final cat1 = await repo.createCategory(name: '薬', color: '#3B82F6');
      final cat2 = await repo.createCategory(name: '症状', color: '#EF4444');

      expect(
        () => repo.reorderCategories([
          (id: cat1.id, sortOrder: 0),
          (id: cat2.id, sortOrder: 2), // 抜け番
        ]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleteCategory はカテゴリを削除する', () async {
      final cat = await repo.createCategory(name: '薬', color: '#3B82F6');

      await repo.deleteCategory(cat.id);

      final categories = await repo.searchCategories();
      expect(categories.length, 0);
    });

    test('deleteCategory は存在しないIDで NotFoundException をスローする', () async {
      expect(
        () => repo.deleteCategory('nonexistent'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
