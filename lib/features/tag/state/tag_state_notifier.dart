import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/db/database.dart';
import '../../../shared/db/dao/tag_repository.dart';

/// タグ一覧の状態管理。
///
/// Repositoryから取得したタグ一覧をポーリングで更新する。
///
/// 使用例:
/// ```dart
/// final tags = ref.watch(tagListProvider('category-id'));
/// tags.when(
///   data: (list) => ListView.builder(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
class TagStateNotifier extends StateNotifier<AsyncValue<List<TagRecord>>> {
  TagStateNotifier(
    this._repository, {
    required String categoryId,
    required bool includeArchived,
  })  : _categoryId = categoryId,
        _includeArchived = includeArchived,
        super(const AsyncValue.loading()) {
    _init();
  }

  final TagRepository _repository;
  final String _categoryId;
  final bool _includeArchived;
  Timer? _timer;

  /// 初期化: 指定カテゴリのタグを定期的に取得する。
  void _init() {
    _loadTags();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _loadTags();
    });
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _repository.searchTags(
        categoryId: _categoryId,
        includeArchived: _includeArchived,
      );
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// タグを作成する。
  Future<void> createTag({required String name}) async {
    try {
      await _repository.createTag(categoryId: _categoryId, name: name);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// タグを更新する。
  Future<void> updateTag({
    required String id,
    required String name,
  }) async {
    try {
      await _repository.updateTag(id: id, name: name);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// タグをアーカイブする。
  Future<void> archiveTag(String id) async {
    try {
      await _repository.updateTag(
        id: id,
        updateArchivedAt: true,
        archivedAt: DateTime.now().toUtc(),
      );
      await _loadTags();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// タグをリストアする。
  Future<void> restoreTag(String id) async {
    try {
      await _repository.updateTag(
        id: id,
        updateArchivedAt: true,
        archivedAt: null,
      );
      await _loadTags();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// タグを削除する（アーカイブ画面からのみ）。
  Future<void> deleteTag(String id) async {
    try {
      await _repository.deleteTag(id);
      await _loadTags();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// タグの並び替えを行う。
  Future<void> reorderTags(List<String> orderedIds) async {
    try {
      final items = orderedIds
          .asMap()
          .entries
          .map((e) => (id: e.value, sortOrder: e.key))
          .toList();
      await _repository.reorderTags(categoryId: _categoryId, items: items);
      await _loadTags();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 全タグ一覧の状態管理（カテゴリ横断）。
///
/// Tags画面で全カテゴリのタグを一括表示する際に使用。
class AllTagsStateNotifier extends StateNotifier<AsyncValue<List<TagRecord>>> {
  AllTagsStateNotifier(this._repository, {required bool includeArchived})
      : _includeArchived = includeArchived,
        super(const AsyncValue.loading()) {
    _init();
  }

  final TagRepository _repository;
  final bool _includeArchived;
  Timer? _timer;

  void _init() {
    _loadTags();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _loadTags();
    });
  }

  Future<void> _loadTags() async {
    try {
      // 全カテゴリのタグを取得するため、categoryIdは空文字列で全件検索
      // TODO: Repository側で全件取得メソッドを追加する方が良い
      final tags = await _repository.searchTags(categoryId: '', includeArchived: _includeArchived);
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
