/// リポジトリ層で使用する例外クラス群
///
/// バリデーションエラー、リソース未存在、重複エラーを定義。
///
/// 使用例:
/// ```dart
/// if (name.isEmpty) {
///   throw ValidationException(
///     'カテゴリ名を入力してください',
///     issues: {'name': ['カテゴリ名を入力してください']},
///   );
/// }
/// ```
///
/// 注意点:
/// - issuesマップはフィールド名ごとにエラーメッセージリストを保持
/// - 半年後に見返しても意図が明確なよう、日本語メッセージを推奨

/// バリデーションエラー
///
/// 入力値が制約違反した場合にスローされる。
class ValidationException implements Exception {
  /// エラーメッセージ（全体のサマリー）
  final String message;

  /// フィールドごとのエラーメッセージ
  ///
  /// キー: フィールド名（例: 'name', 'color'）
  /// 値: エラーメッセージのリスト
  final Map<String, List<String>>? issues;

  const ValidationException(
    this.message, {
    this.issues,
  });

  @override
  String toString() {
    if (issues != null && issues!.isNotEmpty) {
      final details = issues!.entries
          .map((e) => '  ${e.key}: ${e.value.join(', ')}')
          .join('\n');
      return 'ValidationException: $message\n$details';
    }
    return 'ValidationException: $message';
  }
}

/// リソース未存在エラー
///
/// 指定されたIDのレコードが見つからない場合にスローされる。
class NotFoundException implements Exception {
  /// エラーメッセージ
  final String message;

  const NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

/// 重複エラー
///
/// ユニーク制約違反（例: カテゴリ名重複）が発生した場合にスローされる。
class DuplicateException implements Exception {
  /// エラーメッセージ
  final String message;

  /// 重複したフィールド名（例: 'name'）
  final String field;

  const DuplicateException(this.message, this.field);

  @override
  String toString() => 'DuplicateException: $message (field: $field)';
}
