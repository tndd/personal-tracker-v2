import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 選択されたカテゴリIDを管理するProvider。
///
/// nullの場合は全カテゴリを表示。
/// カテゴリIDが指定されている場合は、そのカテゴリのみを表示。
///
/// 使用例:
/// ```dart
/// // 全カテゴリを選択
/// ref.read(selectedCategoryIdProvider.notifier).state = null;
///
/// // 特定カテゴリを選択
/// ref.read(selectedCategoryIdProvider.notifier).state = 'category-id';
/// ```
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);
