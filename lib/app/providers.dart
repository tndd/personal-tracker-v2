import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/db/database.dart';
import '../shared/db/dao/category_repository.dart';
import '../shared/db/dao/tag_repository.dart';
import '../shared/db/dao/track_repository.dart';
import '../shared/db/dao/daily_repository.dart';

/// データベースインスタンスのProvider。
///
/// アプリケーション全体で単一のデータベース接続を共有する。
/// 使用例:
/// ```dart
/// final db = ref.watch(databaseProvider);
/// ```
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

/// CategoryRepositoryのProvider。
///
/// カテゴリの CRUD 操作を提供する。
/// 使用例:
/// ```dart
/// final repo = ref.watch(categoryRepositoryProvider);
/// await repo.createCategory(name: '服薬', color: '#3B82F6');
/// ```
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepository(db);
});

/// TagRepositoryのProvider。
///
/// タグの CRUD 操作を提供する。
/// 使用例:
/// ```dart
/// final repo = ref.watch(tagRepositoryProvider);
/// await repo.createTag(categoryId: 'xxx', name: 'デパス');
/// ```
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TagRepository(db);
});

/// TrackRepositoryのProvider。
///
/// トラック記録の CRUD 操作を提供する。
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TrackRepository(db);
});

/// DailyRepositoryのProvider。
///
/// 日記の CRUD 操作を提供する。
final dailyRepositoryProvider = Provider<DailyRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DailyRepository(db);
});

/// データベースを初期化するヘルパー関数。
///
/// アプリケーション起動時に呼び出し、デフォルトのデータベースインスタンスを作成する。
///
/// 使用例:
/// ```dart
/// final db = await initializeDatabase();
/// runApp(ProviderScope(
///   overrides: [databaseProvider.overrideWithValue(db)],
///   child: MyApp(),
/// ));
/// ```
Future<AppDatabase> initializeDatabase() async {
  return AppDatabase();
}
