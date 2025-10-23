import 'package:flutter/material.dart';

/// アプリケーション全体のテーマ定義。
/// Material 3ベースのライト/ダークテーマを提供する。
class AppTheme {
  AppTheme._();

  /// ライトテーマ
  ///
  /// 使用例:
  /// ```dart
  /// MaterialApp(
  ///   theme: AppTheme.lightTheme,
  /// )
  /// ```
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6), // 青
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }

  /// ダークテーマ
  ///
  /// 使用例:
  /// ```dart
  /// MaterialApp(
  ///   darkTheme: AppTheme.darkTheme,
  ///   themeMode: ThemeMode.dark,
  /// )
  /// ```
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6), // 青
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }
}
