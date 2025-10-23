import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/db/database.dart';
import '../../category/state/category_provider.dart';
import '../../category/ui/category_dialog.dart';

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
class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final CategoryRecord category;

  @override
  Widget build(BuildContext context) {
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
            // TODO: タグ数を表示
            Text(
              '(0)',
              style: Theme.of(context).textTheme.bodySmall,
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
                // TODO: アーカイブ確認ダイアログ
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
                // TODO: タグ一覧を表示
                const Text('タグがありません'),
                const SizedBox(height: 8),
                // タグ追加ボタン
                TextButton.icon(
                  onPressed: () {
                    // TODO: タグ追加ダイアログ
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
