import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_tracker_v2/app/router.dart';

void main() {
  group('Router', () {
    test('appRouter はGoRouterインスタンスである', () {
      expect(appRouter, isA<GoRouter>());
    });

    test('appRouter は定義されたルートを持つ', () {
      final router = appRouter;
      expect(router, isNotNull);
      expect(router.routeInformationProvider, isNotNull);
    });
  });
}
