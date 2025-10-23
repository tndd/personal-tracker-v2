import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// サイドナビゲーション付きのScaffold。
///
/// 全画面で共有するレイアウトを提供する。
/// 左側にナビゲーションレール、右側にメインコンテンツを配置。
///
/// 使用例:
/// ```dart
/// ScaffoldWithNav(child: TagsPage())
/// ```
class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          // 左側: ナビゲーションレール
          NavigationRail(
            selectedIndex: _getSelectedIndex(currentPath),
            onDestinationSelected: (index) {
              _onDestinationSelected(context, index);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Health Tracker',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.track_changes_outlined),
                selectedIcon: Icon(Icons.track_changes),
                label: Text('Track'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Daily'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Analysis'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.label_outlined),
                selectedIcon: Icon(Icons.label),
                label: Text('Tags'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 右側: メインコンテンツ
          Expanded(child: child),
        ],
      ),
    );
  }

  /// 現在のパスに対応するナビゲーションインデックスを取得する。
  int _getSelectedIndex(String path) {
    if (path.startsWith('/track')) return 0;
    if (path.startsWith('/daily')) return 1;
    if (path.startsWith('/analysis')) return 2;
    if (path.startsWith('/tags')) return 3;
    return 3; // デフォルトはTags
  }

  /// ナビゲーション項目が選択されたときの処理。
  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/track');
      case 1:
        context.go('/daily');
      case 2:
        context.go('/analysis');
      case 3:
        context.go('/tags');
    }
  }
}
