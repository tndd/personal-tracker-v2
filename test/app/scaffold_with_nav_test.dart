import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/app/providers.dart';
import 'package:personal_tracker_v2/app/scaffold_with_nav.dart';
import 'package:personal_tracker_v2/features/tag/ui/tags_page.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';

void main() {
  testWidgets('幅が広い場合はサイドバーが常時表示される', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    binding.window.physicalSizeTestValue = const Size(1200, 800);
    binding.window.devicePixelRatioTestValue = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: ScaffoldWithNav(child: TagsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Health Tracker'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('幅が狭い場合はハンバーガーからサイドバーを開閉できる', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase.memory();
    addTearDown(() async {
      await db.close();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    binding.window.physicalSizeTestValue = const Size(600, 800);
    binding.window.devicePixelRatioTestValue = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: ScaffoldWithNav(child: TagsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('メニュー'), findsOneWidget);
    expect(
      tester.widget<AnimatedOpacity>(
        find.byKey(const ValueKey('navPanelOpacity')),
      ).opacity,
      0,
    );

    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(
        find.byKey(const ValueKey('navPanelOpacity')),
      ).opacity,
      1,
    );

    await tester.tapAt(const Offset(520, 100));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedOpacity>(
        find.byKey(const ValueKey('navPanelOpacity')),
      ).opacity,
      0,
    );
  });
}
