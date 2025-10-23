import 'package:flutter/material.dart';

/// カテゴリ作成時に使用するカラーパレット。
///
/// 8色の定義済みカラーから選択する。
/// カスタム色は現時点では非対応。
///
/// 使用例:
/// ```dart
/// final selectedColor = ColorPalette.presets[0]; // 青を選択
/// final colorHex = selectedColor['value']; // '#3B82F6'
/// ```
class ColorPalette {
  ColorPalette._();

  /// カラープリセット一覧（名前とHEX値のペア）。
  ///
  /// validation.mdの定義に基づく8色。
  static const presets = [
    {'name': '青', 'value': '#3B82F6'},
    {'name': '赤', 'value': '#EF4444'},
    {'name': '緑', 'value': '#10B981'},
    {'name': '黄', 'value': '#F59E0B'},
    {'name': '紫', 'value': '#8B5CF6'},
    {'name': 'ピンク', 'value': '#EC4899'},
    {'name': 'シアン', 'value': '#06B6D4'},
    {'name': 'オレンジ', 'value': '#F97316'},
  ];

  /// HEX文字列からColorオブジェクトを生成する。
  ///
  /// 使用例:
  /// ```dart
  /// final color = ColorPalette.fromHex('#3B82F6');
  /// ```
  ///
  /// 注意点:
  /// - HEX文字列は '#RRGGBB' 形式である必要がある
  /// - 不正な形式の場合は透明色を返す
  static Color fromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 7 && hexString.startsWith('#')) {
        buffer.write('ff');
        buffer.write(hexString.substring(1));
      } else {
        return Colors.transparent;
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.transparent;
    }
  }

  /// ColorオブジェクトからHEX文字列に変換する。
  ///
  /// 使用例:
  /// ```dart
  /// final hex = ColorPalette.toHex(Colors.blue);
  /// // => '#2196F3'
  /// ```
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
