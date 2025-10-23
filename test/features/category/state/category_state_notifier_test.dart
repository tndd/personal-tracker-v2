import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/app/providers.dart';
import 'package:personal_tracker_v2/features/category/state/category_provider.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';

void main() {
  group('CategoryStateNotifier', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.memory();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
    });

    tearDown(() async {
      await db.close();
      container.dispose();
    });

    test('初期状態はloading', () {
      final state = container.read(categoryListProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('カテゴリを作成すると一覧に反映される', () async {
      final notifier = container.read(categoryNotifierProvider);

      await notifier.createCategory(name: '服薬', color: '#3B82F6');

      // ポーリングの更新を待つ
      await Future.delayed(const Duration(milliseconds: 600));

      final state = container.read(categoryListProvider);
      state.when(
        data: (categories) {
          expect(categories.length, equals(1));
          expect(categories.first.name, equals('服薬'));
          expect(categories.first.color, equals('#3B82F6'));
        },
        loading: () => fail('まだloading状態'),
        error: (e, st) => fail('エラーが発生: $e'),
      );
    });

    test('カテゴリをアーカイブすると一覧から除外される', () async {
      final notifier = container.read(categoryNotifierProvider);

      await notifier.createCategory(name: '服薬', color: '#3B82F6');
      await Future.delayed(const Duration(milliseconds: 600));

      final state1 = container.read(categoryListProvider);
      final categoryId = state1.value!.first.id;

      await notifier.archiveCategory(categoryId);
      await Future.delayed(const Duration(milliseconds: 600));

      final state2 = container.read(categoryListProvider);
      state2.when(
        data: (categories) {
          expect(categories.length, equals(0));
        },
        loading: () => fail('まだloading状態'),
        error: (e, st) => fail('エラーが発生: $e'),
      );
    });

    test('複数カテゴリの並び替えが正しく動作する', () async {
      final notifier = container.read(categoryNotifierProvider);

      await notifier.createCategory(name: 'カテゴリA', color: '#3B82F6');
      await notifier.createCategory(name: 'カテゴリB', color: '#EF4444');
      await Future.delayed(const Duration(milliseconds: 600));

      final state1 = container.read(categoryListProvider);
      final ids = state1.value!.map((c) => c.id).toList();

      // 逆順に並び替え
      await notifier.reorderCategories(ids.reversed.toList());
      await Future.delayed(const Duration(milliseconds: 600));

      final state2 = container.read(categoryListProvider);
      state2.when(
        data: (categories) {
          expect(categories.length, equals(2));
          expect(categories.first.name, equals('カテゴリB'));
          expect(categories.last.name, equals('カテゴリA'));
        },
        loading: () => fail('まだloading状態'),
        error: (e, st) => fail('エラーが発生: $e'),
      );
    });
  });
}
