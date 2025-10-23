import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/database.dart';
import '../../category/state/category_provider.dart';
import '../../category/ui/category_dialog.dart';
import '../state/tag_provider.dart';
import 'tag_dialog.dart';

/// アーカイブされたカテゴリとタグの管理画面。
///
/// アーカイブ済みのカテゴリとタグを一覧表示し、
/// レストアまたは削除を行う。
class ArchivedTagsPage extends ConsumerWidget {
  const ArchivedTagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(archivedCategoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/tags');
          },
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text('アーカイブされたカテゴリはありません'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _ArchivedCategorySection(category: categories[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}

/// アーカイブされたカテゴリセクション。
class _ArchivedCategorySection extends ConsumerWidget {
  const _ArchivedCategorySection({required this.category});

  final CategoryRecord category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(archivedTagListByCategoryProvider(category.id));

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
              icon: const Icon(Icons.restore),
              onPressed: () {
                ref.read(categoryNotifierProvider).restoreCategory(category.id);
              },
              tooltip: 'レストア',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              onPressed: () {
                _showDeleteCategoryDialog(context, ref, category);
              },
              tooltip: '削除',
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
                        return _ArchivedTagItem(
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

  void _showDeleteCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryRecord category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリを削除'),
        content: Text(
          'カテゴリ「${category.name}」を完全に削除しますか？\n'
          'この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(categoryNotifierProvider).deleteCategory(category.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

/// アーカイブされたタグアイテム。
class _ArchivedTagItem extends ConsumerWidget {
  const _ArchivedTagItem({
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
          IconButton(
            icon: const Icon(Icons.restore, size: 20),
            onPressed: () {
              ref.read(archivedTagListByCategoryProvider(tag.categoryId).notifier)
                  .restoreTag(tag.id);
            },
            tooltip: 'レストア',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined, size: 20),
            onPressed: () {
              _showDeleteTagDialog(context, ref, tag);
            },
            tooltip: '削除',
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

  void _showDeleteTagDialog(
    BuildContext context,
    WidgetRef ref,
    TagRecord tag,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグを削除'),
        content: Text(
          'タグ「${tag.name}」を完全に削除しますか？\n'
          '全てのトラックから該当タグが削除されます。\n'
          'この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(archivedTagListByCategoryProvider(tag.categoryId).notifier)
                  .deleteTag(tag.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
