import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../shared/db/database.dart';
import 'category_state_notifier.dart';

/// カテゴリ一覧（アーカイブ除外）のProvider。
///
/// 使用例:
/// ```dart
/// final categories = ref.watch(categoryListProvider);
/// categories.when(
///   data: (list) => Text('カテゴリ数: ${list.length}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
final categoryListProvider =
    StateNotifierProvider<CategoryStateNotifier, AsyncValue<List<CategoryRecord>>>(
  (ref) {
    final repository = ref.watch(categoryRepositoryProvider);
    return CategoryStateNotifier(repository);
  },
);

/// アーカイブされたカテゴリ一覧のProvider。
///
/// 使用例:
/// ```dart
/// final archivedCategories = ref.watch(archivedCategoryListProvider);
/// ```
final archivedCategoryListProvider =
    StateNotifierProvider<ArchivedCategoryStateNotifier, AsyncValue<List<CategoryRecord>>>(
  (ref) {
    final repository = ref.watch(categoryRepositoryProvider);
    return ArchivedCategoryStateNotifier(repository);
  },
);

/// カテゴリ一覧をアクション操作するためのProvider。
///
/// 使用例:
/// ```dart
/// final notifier = ref.read(categoryNotifierProvider.notifier);
/// await notifier.createCategory(name: '服薬', color: '#3B82F6');
/// ```
final categoryNotifierProvider = categoryListProvider.notifier;
