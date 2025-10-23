import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/db/database.dart';
import '../../../shared/db/dao/category_repository.dart';

/// カテゴリ一覧の状態管理。
///
/// Repositoryから取得したカテゴリ一覧をポーリングで更新する。
///
/// 使用例:
/// ```dart
/// final categories = ref.watch(categoryListProvider);
/// categories.when(
///   data: (list) => ListView.builder(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
class CategoryStateNotifier extends StateNotifier<AsyncValue<List<CategoryRecord>>> {
  CategoryStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  final CategoryRepository _repository;
  Timer? _timer;

  /// 初期化: アーカイブされていないカテゴリを定期的に取得する。
  void _init() {
    _loadCategories();
    // 500msごとにポーリング
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.searchCategories(includeArchived: false);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// カテゴリを作成する。
  ///
  /// バリデーションはUI層で行うことを想定。
  /// Repository層でのエラー（重複など）はAsyncValueのerrorに反映される。
  Future<void> createCategory({
    required String name,
    required String color,
  }) async {
    try {
      await _repository.createCategory(name: name, color: color);
      // Streamが自動的に更新されるため、stateの手動更新は不要
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// カテゴリを更新する。
  Future<void> updateCategory({
    required String id,
    required String name,
    required String color,
  }) async {
    try {
      await _repository.updateCategory(id: id, name: name, color: color);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// カテゴリをアーカイブする。
  Future<void> archiveCategory(String id) async {
    try {
      await _repository.updateCategory(
        id: id,
        updateArchivedAt: true,
        archivedAt: DateTime.now().toUtc(),
      );
      await _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// カテゴリをリストアする。
  Future<void> restoreCategory(String id) async {
    try {
      await _repository.updateCategory(
        id: id,
        updateArchivedAt: true,
        archivedAt: null,
      );
      await _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// カテゴリを削除する（アーカイブ画面からのみ）。
  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// カテゴリの並び替えを行う。
  Future<void> reorderCategories(List<String> orderedIds) async {
    try {
      final items = orderedIds
          .asMap()
          .entries
          .map((e) => (id: e.value, sortOrder: e.key))
          .toList();
      await _repository.reorderCategories(items);
      await _loadCategories();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// アーカイブされたカテゴリ一覧の状態管理。
class ArchivedCategoryStateNotifier extends StateNotifier<AsyncValue<List<CategoryRecord>>> {
  ArchivedCategoryStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  final CategoryRepository _repository;
  Timer? _timer;

  void _init() {
    _loadCategories();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.searchCategories(includeArchived: true);
      // アーカイブされたもののみフィルタ
      final archived = categories.where((c) => c.archivedAt != null).toList();
      state = AsyncValue.data(archived);
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
