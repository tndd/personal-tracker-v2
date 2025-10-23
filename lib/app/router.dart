import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/tag/ui/tags_page.dart';
import '../features/tag/ui/archived_tags_page.dart';
import 'scaffold_with_nav.dart';

/// アプリケーション全体のルーティング設定。
///
/// GoRouterを使用して、画面遷移とURLマッピングを定義する。
///
/// 使用例:
/// ```dart
/// MaterialApp.router(
///   routerConfig: appRouter,
/// )
/// ```
final appRouter = GoRouter(
  initialLocation: '/tags',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNav(child: child);
      },
      routes: [
        GoRoute(
          path: '/tags',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TagsPage(),
          ),
        ),
        GoRoute(
          path: '/track',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _PlaceholderPage(title: 'Track'),
          ),
        ),
        GoRoute(
          path: '/daily',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _PlaceholderPage(title: 'Daily'),
          ),
        ),
        GoRoute(
          path: '/analysis',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _PlaceholderPage(title: 'Analysis'),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/tags/archived',
      builder: (context, state) => const ArchivedTagsPage(),
    ),
  ],
);

/// プレースホルダー画面。
/// Phase3以降で実装予定の画面の仮表示用。
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title (未実装)',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
