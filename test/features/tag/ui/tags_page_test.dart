import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/app/providers.dart';
import 'package:personal_tracker_v2/features/tag/ui/tags_page.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';

void main() {
  group('TagsPage', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('カテゴリがない場合、メッセージが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: TagsPage(),
          ),
        ),
      );

      // 初期loading状態
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // データ取得を待つ
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // メッセージが表示される
      expect(find.text('カテゴリがありません。\n右上のボタンから追加してください。'), findsOneWidget);
    });

    testWidgets('AppBarにタイトルとカテゴリ追加ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: TagsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('カテゴリとタグの管理'), findsOneWidget);
      expect(find.text('カテゴリ 追加'), findsOneWidget);
    });

    testWidgets('Archivedリンクが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: TagsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      expect(find.text('Archived'), findsOneWidget);
    });
  });
}
