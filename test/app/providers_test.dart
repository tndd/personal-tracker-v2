import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/app/providers.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';

void main() {
  group('Providers', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      // テスト用のインメモリデータベースを作成
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

    test('databaseProvider はオーバーライドなしではエラーをスローする', () {
      final emptyContainer = ProviderContainer();
      expect(
        () => emptyContainer.read(databaseProvider),
        throwsUnimplementedError,
      );
      emptyContainer.dispose();
    });

    test('categoryRepositoryProvider はCategoryRepositoryを返す', () {
      final repo = container.read(categoryRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo.runtimeType.toString(), contains('CategoryRepository'));
    });

    test('tagRepositoryProvider はTagRepositoryを返す', () {
      final repo = container.read(tagRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo.runtimeType.toString(), contains('TagRepository'));
    });

    test('trackRepositoryProvider はTrackRepositoryを返す', () {
      final repo = container.read(trackRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo.runtimeType.toString(), contains('TrackRepository'));
    });

    test('dailyRepositoryProvider はDailyRepositoryを返す', () {
      final repo = container.read(dailyRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo.runtimeType.toString(), contains('DailyRepository'));
    });
  });
}
