import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/app/theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme はMaterial 3を使用する', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('darkTheme はMaterial 3を使用する', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('lightTheme と darkTheme は異なるColorSchemeを持つ', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(
        lightTheme.colorScheme.brightness,
        isNot(equals(darkTheme.colorScheme.brightness)),
      );
    });

    test('テーマのカード形状は丸みを帯びている', () {
      final theme = AppTheme.lightTheme;
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, equals(BorderRadius.circular(12)));
    });
  });
}
