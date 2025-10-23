import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/shared/constants/color_palette.dart';

void main() {
  group('ColorPalette', () {
    test('プリセットは8色を含む', () {
      expect(ColorPalette.presets.length, equals(8));
    });

    test('各プリセットはnameとvalueを持つ', () {
      for (final preset in ColorPalette.presets) {
        expect(preset.containsKey('name'), isTrue);
        expect(preset.containsKey('value'), isTrue);
        expect(preset['name'], isNotEmpty);
        expect(preset['value'], startsWith('#'));
        expect(preset['value']?.length, equals(7));
      }
    });

    test('fromHex は正しいColorオブジェクトを生成する', () {
      final color = ColorPalette.fromHex('#3B82F6');
      expect(color, isA<Color>());
      expect(color.value, equals(0xFF3B82F6));
    });

    test('fromHex は不正な形式で透明色を返す', () {
      final color = ColorPalette.fromHex('invalid');
      expect(color, equals(Colors.transparent));
    });

    test('toHex はColorオブジェクトをHEX文字列に変換する', () {
      final color = const Color(0xFF3B82F6);
      final hex = ColorPalette.toHex(color);
      expect(hex, equals('#3B82F6'));
    });

    test('fromHex と toHex は可逆である', () {
      const originalHex = '#EF4444';
      final color = ColorPalette.fromHex(originalHex);
      final convertedHex = ColorPalette.toHex(color);
      expect(convertedHex, equals(originalHex));
    });

    test('全プリセットのHEX値が有効である', () {
      for (final preset in ColorPalette.presets) {
        final hexValue = preset['value']!;
        final color = ColorPalette.fromHex(hexValue);
        expect(color, isNot(equals(Colors.transparent)),
            reason: '$hexValue は有効なHEX値である必要があります');
      }
    });
  });
}
