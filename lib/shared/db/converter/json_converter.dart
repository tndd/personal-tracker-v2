/// JSON配列とList<String>の相互変換コンバーター
///
/// Driftで使用し、tagIdsフィールドをJSON文字列として保存・読み込みする。
///
/// 使用例:
/// ```dart
/// // Drift テーブル定義内で使用
/// TextColumn get tagIds => text().map(const StringListConverter())();
/// ```
///
/// 注意点:
/// - JSON文字列が不正な場合は空配列を返す
/// - 半年後に見返しても意図が明確なようエラーハンドリングを含める
import 'dart:convert';
import 'package:drift/drift.dart';

/// String List（タグID配列）とJSON文字列の相互変換
///
/// データベース保存時: List<String> → JSON文字列
/// データベース読込時: JSON文字列 → List<String>
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    try {
      final decoded = json.decode(fromDb);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      // JSON配列でない場合は空配列を返す
      return [];
    } catch (e) {
      // パースエラー時も空配列を返す（データ破損時の防御）
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}
