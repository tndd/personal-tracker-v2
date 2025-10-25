import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/category/state/category_provider.dart';
import '../features/tag/state/selected_category_provider.dart';

/// サイドナビゲーション付きのScaffold。
///
/// 全画面で共有するレイアウトを提供する。
/// 左側にカスタムナビゲーション、右側にメインコンテンツを配置。
class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isTagsPage = currentPath.startsWith('/tags');

    return Scaffold(
      body: Row(
        children: [
          // 左側: カスタムナビゲーション
          Container(
            width: 300,
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Health Tracker',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // ナビゲーション項目
                _NavItem(
                  icon: Icons.track_changes_outlined,
                  selectedIcon: Icons.track_changes,
                  label: 'Track',
                  isSelected: currentPath.startsWith('/track'),
                  onTap: () => context.go('/track'),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today,
                  label: 'Daily',
                  isSelected: currentPath.startsWith('/daily'),
                  onTap: () => context.go('/daily'),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  label: 'Analysis',
                  isSelected: currentPath.startsWith('/analysis'),
                  onTap: () => context.go('/analysis'),
                ),
                _NavItem(
                  icon: Icons.label_outlined,
                  selectedIcon: Icons.label,
                  label: 'Tags',
                  isSelected: currentPath.startsWith('/tags'),
                  onTap: () => context.go('/tags'),
                ),
                // Tagsページの場合のみ、タグ一覧を表示
                if (isTagsPage) ...[
                  const Divider(),
                  Expanded(
                    child: _TagsFilterSection(),
                  ),
                ],
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 右側: メインコンテンツ
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// ナビゲーション項目。
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected
            ? colorScheme.secondaryContainer.withOpacity(0.5)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tagsページ用のフィルタセクション。
///
/// 「ALL」ボタンとカテゴリ一覧を表示する。
class _TagsFilterSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ALLボタン
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                // 全カテゴリを表示
                ref.read(selectedCategoryIdProvider.notifier).state = null;
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              child: const Text('ALL'),
            ),
          ),
          const SizedBox(height: 16),
          // カテゴリ一覧ヘッダー
          Text(
            'カテゴリ一覧',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          // カテゴリリスト
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text('カテゴリがありません');
                }
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryFilterItem(
                      categoryId: category.id,
                      name: category.name,
                      color: category.color,
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('エラー: $error'),
            ),
          ),
        ],
      ),
    );
  }
}

/// カテゴリフィルタ項目。
class _CategoryFilterItem extends ConsumerWidget {
  const _CategoryFilterItem({
    required this.categoryId,
    required this.name,
    required this.color,
  });

  final String categoryId;
  final String name;
  final String color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _parseColor(color);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final isSelected = selectedCategoryId == categoryId;

    return InkWell(
      onTap: () {
        // このカテゴリを選択
        ref.read(selectedCategoryIdProvider.notifier).state = categoryId;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        color: isSelected
            ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: categoryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// カラーコード文字列をColorに変換する。
  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.substring(1));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
