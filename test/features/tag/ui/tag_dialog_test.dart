import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/app/providers.dart';
import 'package:personal_tracker_v2/features/tag/ui/tag_dialog.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';

void main() {
  group('TagDialog', () {
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
              body: TagDialog(
                categoryId: 'test-category',
                categoryName: '服薬',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('タグ追加 - 服薬'), findsOneWidget);
      expect(find.text('タグ名'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
    });
  });
}
