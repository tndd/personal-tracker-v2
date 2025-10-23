import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/app/providers.dart';
import 'package:personal_tracker_v2/features/category/ui/category_dialog.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';

void main() {
  group('CategoryDialog', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('ダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CategoryDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('カテゴリ追加'), findsOneWidget);
      expect(find.text('カテゴリ名'), findsOneWidget);
      expect(find.text('色'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
    });

    testWidgets('8色のカラーパレットが表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CategoryDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 8色のカラーボタンが表示される
      expect(find.text('青'), findsOneWidget);
      expect(find.text('赤'), findsOneWidget);
      expect(find.text('緑'), findsOneWidget);
      expect(find.text('黄'), findsOneWidget);
      expect(find.text('紫'), findsOneWidget);
      expect(find.text('ピンク'), findsOneWidget);
      expect(find.text('シアン'), findsOneWidget);
      expect(find.text('オレンジ'), findsOneWidget);
    });

    testWidgets('編集モードではタイトルが「カテゴリ編集」になる', (tester) async {
      final category = CategoryRecord(
        id: 'test-id',
        name: '服薬',
        color: '#3B82F6',
        sortOrder: 0,
        archivedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CategoryDialog(category: category),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('カテゴリ編集'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });
  });
}
