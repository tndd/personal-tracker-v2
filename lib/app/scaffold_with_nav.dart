import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/category/state/category_provider.dart';
import '../features/tag/state/selected_category_provider.dart';

/// ナビゲーションパネルの開閉状態を共有するProvider。
///
/// 使用例:
/// ```dart
/// ref.read(navPanelVisibilityProvider.notifier).state = true;
/// ```
///
/// 注意点: ScaffoldWithNav 内でのUI制御専用。外部で任意にoverrideすると
/// レイアウト破綻を招くため避けること。
final navPanelVisibilityProvider = StateProvider<bool>((ref) => false);

/// 現在レイアウトがコンパクト幅かどうかを共有するProvider。
///
/// 使用例:
/// ```dart
/// final isCompact = ref.watch(isCompactLayoutProvider);
/// ```
///
/// 注意点: ScaffoldWithNavが設定する値に依存するため、他ウィジェットで
/// 明示的に値を変更しないこと。
final isCompactLayoutProvider = Provider<bool>((ref) => false);

/// サイドナビゲーション付きのScaffold。
///
/// 全画面で共有するレイアウトを提供する。
/// 左側にカスタムナビゲーション、右側にメインコンテンツを配置。
class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String currentPath;
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {
      currentPath = '';
    }
    final isTagsPage = currentPath.startsWith('/tags');

    final mediaSize = MediaQuery.of(context).size;
    final isCompact = mediaSize.width < mediaSize.height;
    final isNavOpen = ref.watch(navPanelVisibilityProvider);
    final navController = ref.read(navPanelVisibilityProvider.notifier);

    if (!isCompact && isNavOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navController.state = false;
      });
    }

    final navColor = Theme.of(context).colorScheme.surfaceContainerLowest;
    final navContent = SafeArea(
      child: Container(
        color: navColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'メニューを閉じる',
                  onPressed: () {
                    navController.state = false;
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Health Tracker',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
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
            if (isTagsPage) ...[
              const Divider(),
              Expanded(
                child: _TagsFilterSection(),
              ),
            ],
          ],
        ),
      ),
    );

    if (!isCompact) {
      return ProviderScope(
        overrides: [
          isCompactLayoutProvider.overrideWithValue(false),
        ],
        child: Scaffold(
          body: Row(
            children: [
              SizedBox(width: 300, child: navContent),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        isCompactLayoutProvider.overrideWithValue(true),
      ],
      child: Stack(
        children: [
          child,
          IgnorePointer(
            ignoring: !isNavOpen,
            child: AnimatedOpacity(
              key: const ValueKey('navOverlayOpacity'),
              opacity: isNavOpen ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  navController.state = false;
                },
                child: Container(
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            key: const ValueKey('navPanelSlide'),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            left: isNavOpen ? 0 : -300,
            child: SizedBox(
              width: 300,
              child: AnimatedOpacity(
                key: const ValueKey('navPanelOpacity'),
                opacity: isNavOpen ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Material(
                  elevation: 4,
                  child: navContent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ナビゲーション項目。
class _NavItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = ref.watch(isCompactLayoutProvider);

    return InkWell(
      onTap: () {
        onTap();
        if (isCompact) {
          ref.read(navPanelVisibilityProvider.notifier).state = false;
        }
      },
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
    final isCompact = ref.watch(isCompactLayoutProvider);

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
                if (isCompact) {
                  ref.read(navPanelVisibilityProvider.notifier).state = false;
                }
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
    final isCompact = ref.watch(isCompactLayoutProvider);

    return InkWell(
      onTap: () {
        // このカテゴリを選択
        ref.read(selectedCategoryIdProvider.notifier).state = categoryId;
        if (isCompact) {
          ref.read(navPanelVisibilityProvider.notifier).state = false;
        }
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
