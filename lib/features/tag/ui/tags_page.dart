import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/database.dart';
import '../../category/state/category_provider.dart';
import '../../category/ui/category_dialog.dart';
import '../state/tag_provider.dart';
import 'tag_dialog.dart';

/// Tags画面（カテゴリとタグの管理）。
///
/// カテゴリごとにセクション分けし、各セクション内にタグ一覧を表示する。
///
/// 使用例:
/// ```dart
/// MaterialApp.router(
///   routerConfig: appRouter,
/// )
/// ```
class TagsPage extends ConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tags'),
            Text(
              'カテゴリとタグの管理',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // カテゴリ追加ボタン
          FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CategoryDialog(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('カテゴリ 追加'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Text('カテゴリがありません。\n右上のボタンから追加してください。'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _CategorySection(category: categories[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('エラー: $error')),
            ),
          ),
          // Archivedリンク
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                context.go('/tags/archived');
              },
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archived'),
            ),
          ),
        ],
      ),
    );
  }
}

/// カテゴリセクション（アコーディオン形式）。
class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.category});

  final CategoryRecord category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagListByCategoryProvider(category.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(category.color),
          radius: 12,
        ),
        title: Row(
          children: [
            Text(category.name),
            const SizedBox(width: 8),
            tagsAsync.when(
              data: (tags) => Text(
                '(${tags.length})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              loading: () => const Text('(...)'),
              error: (_, __) => const Text('(?)'),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => CategoryDialog(category: category),
                );
              },
              tooltip: '編集',
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              onPressed: () {
                ref.read(categoryNotifierProvider).archiveCategory(category.id);
              },
              tooltip: 'アーカイブ',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タグ一覧
                tagsAsync.when(
                  data: (tags) {
                    if (tags.isEmpty) {
                      return const Text('タグがありません');
                    }
                    return Column(
                      children: tags.map((tag) {
                        return _TagItem(
                          tag: tag,
                          categoryColor: category.color,
                          categoryName: category.name,
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('エラー: $error'),
                ),
                const SizedBox(height: 8),
                // タグ追加ボタン
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => TagDialog(
                        categoryId: category.id,
                        categoryName: category.name,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('タグ追加'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.substring(1));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// タグアイテム。
class _TagItem extends ConsumerWidget {
  const _TagItem({
    required this.tag,
    required this.categoryColor,
    required this.categoryName,
  });

  final TagRecord tag;
  final String categoryColor;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(categoryColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tag.name,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
          // 編集ボタン
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => TagDialog(
                  categoryId: tag.categoryId,
                  categoryName: categoryName,
                  tag: tag,
                ),
              );
            },
            tooltip: '編集',
          ),
          // アーカイブボタン
          IconButton(
            icon: const Icon(Icons.archive_outlined, size: 20),
            onPressed: () {
              final notifier = ref.read(tagListByCategoryProvider(tag.categoryId).notifier);
              notifier.archiveTag(tag.id);
            },
            tooltip: 'アーカイブ',
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.substring(1));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
