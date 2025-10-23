import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../shared/db/database.dart';
import 'tag_state_notifier.dart';

/// カテゴリ別タグ一覧（アーカイブ除外）のProvider。
///
/// 使用例:
/// ```dart
/// final tags = ref.watch(tagListByCategoryProvider('category-id'));
/// tags.when(
///   data: (list) => Text('タグ数: ${list.length}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
final tagListByCategoryProvider = StateNotifierProvider.family<
    TagStateNotifier,
    AsyncValue<List<TagRecord>>,
    String>(
  (ref, categoryId) {
    final repository = ref.watch(tagRepositoryProvider);
    return TagStateNotifier(
      repository,
      categoryId: categoryId,
      includeArchived: false,
    );
  },
);

/// 全タグ一覧（アーカイブ除外、カテゴリ横断）のProvider。
///
/// 使用例:
/// ```dart
/// final allTags = ref.watch(allTagsProvider);
/// ```
final allTagsProvider =
    StateNotifierProvider<AllTagsStateNotifier, AsyncValue<List<TagRecord>>>(
  (ref) {
    final repository = ref.watch(tagRepositoryProvider);
    return AllTagsStateNotifier(repository, includeArchived: false);
  },
);

/// アーカイブされた全タグ一覧のProvider。
///
/// 使用例:
/// ```dart
/// final archivedTags = ref.watch(archivedAllTagsProvider);
/// ```
final archivedAllTagsProvider =
    StateNotifierProvider<AllTagsStateNotifier, AsyncValue<List<TagRecord>>>(
  (ref) {
    final repository = ref.watch(tagRepositoryProvider);
    return AllTagsStateNotifier(repository, includeArchived: true);
  },
);
