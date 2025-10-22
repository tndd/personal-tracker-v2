import 'package:flutter/material.dart';

/// エントリーポイント。現時点ではバックエンド実装が中心のため、
/// シンプルなプレースホルダー画面のみを表示する。
void main() {
  runApp(const _PlaceholderApp());
}

class _PlaceholderApp extends StatelessWidget {
  const _PlaceholderApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('personal-tracker-v2 backend-in-progress'),
        ),
      ),
    );
  }
}
