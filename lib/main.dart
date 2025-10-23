import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';

/// アプリケーションのエントリーポイント。
///
/// データベースを初期化し、Riverpodのプロバイダーをオーバーライドしてアプリを起動する。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // データベースを初期化
  final database = await initializeDatabase();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const MyApp(),
    ),
  );
}

/// アプリケーションのルートウィジェット。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Personal Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
