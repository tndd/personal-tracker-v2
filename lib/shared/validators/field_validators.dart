/// フィールドバリデーション関数群
///
/// 各入力フィールドのバリデーションルールを実装。
///
/// 使用例:
/// ```dart
/// final error = validateCategoryName(name, existingNames: ['薬', '症状']);
/// if (error != null) {
///   throw ValidationException(error);
/// }
/// ```
///
/// 注意点:
/// - 戻り値がnullなら検証成功、非nullならエラーメッセージ
/// - エラーメッセージは日本語で統一
/// - 半年後に見返しても意図が明確なよう、制約理由をコメント記載

/// カテゴリ名のバリデーション
///
/// 制約:
/// - 必須（空文字・null不可）
/// - 1文字以上50文字以内
/// - 既存のカテゴリ名と重複不可
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateCategoryName(
  String? value, {
  required List<String> existingNames,
  String? currentName,
}) {
  if (value == null || value.trim().isEmpty) {
    return 'カテゴリ名を入力してください';
  }

  final trimmed = value.trim();

  if (trimmed.length > 50) {
    return 'カテゴリ名は50文字以内で入力してください';
  }

  // 更新時は現在の名前との重複を許可
  if (currentName != null && trimmed == currentName) {
    return null;
  }

  if (existingNames.contains(trimmed)) {
    return 'このカテゴリ名は既に使用されています';
  }

  return null;
}

/// カラーコードのバリデーション
///
/// 制約:
/// - 必須
/// - #RRGGBB形式（例: #FF5733）
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateColor(String? value) {
  if (value == null || value.isEmpty) {
    return 'カラーコードを入力してください';
  }

  final pattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
  if (!pattern.hasMatch(value)) {
    return '#RRGGBB 形式で入力してください（例: #FF5733）';
  }

  return null;
}

/// タグ名のバリデーション
///
/// 制約:
/// - 必須（空文字・null不可）
/// - 1文字以上50文字以内
/// - 同一カテゴリ内で重複不可
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateTagName(
  String? value, {
  required List<String> existingNamesInCategory,
  String? currentName,
}) {
  if (value == null || value.trim().isEmpty) {
    return 'タグ名を入力してください';
  }

  final trimmed = value.trim();

  if (trimmed.length > 50) {
    return 'タグ名は50文字以内で入力してください';
  }

  // 更新時は現在の名前との重複を許可
  if (currentName != null && trimmed == currentName) {
    return null;
  }

  if (existingNamesInCategory.contains(trimmed)) {
    return 'このタグ名は既に使用されています';
  }

  return null;
}

/// トラックメモのバリデーション
///
/// 制約:
/// - 任意（nullable）
/// - 最大1000文字
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateTrackMemo(String? value) {
  if (value != null && value.length > 1000) {
    return 'メモは1000文字以内で入力してください';
  }
  return null;
}

/// 日記メモのバリデーション
///
/// 制約:
/// - 任意（nullable）
/// - 最大5000文字
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateDailyMemo(String? value) {
  if (value != null && value.length > 5000) {
    return '日記は5000文字以内で入力してください';
  }
  return null;
}

/// コンディションのバリデーション
///
/// 制約:
/// - -2〜2の整数
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateCondition(int? value) {
  if (value == null || value < -2 || value > 2) {
    return 'コンディションは-2から2の間で選択してください';
  }
  return null;
}

/// 睡眠時刻のバリデーション
///
/// 制約:
/// - sleepEndはsleepStartより後でなければならない
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateSleepTimes(DateTime? sleepStart, DateTime? sleepEnd) {
  if (sleepStart != null && sleepEnd != null) {
    if (sleepEnd.isBefore(sleepStart) || sleepEnd.isAtSameMomentAs(sleepStart)) {
      return '起床時刻は就寝時刻より後に設定してください';
    }
  }
  return null;
}

/// 日付形式のバリデーション
///
/// 制約:
/// - YYYY-MM-DD形式
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateDateFormat(String? value) {
  if (value == null || value.isEmpty) {
    return '日付を指定してください';
  }

  final pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  if (!pattern.hasMatch(value)) {
    return '日付はYYYY-MM-DD形式で指定してください';
  }

  // パース可能かチェック
  try {
    DateTime.parse(value);
  } catch (e) {
    return '無効な日付です';
  }

  return null;
}

/// 並び替えのバリデーション
///
/// 制約:
/// - 指定ID数が対象レコード数と一致
/// - sortOrderが0からの連番（重複・抜け番禁止）
///
/// 戻り値: エラーメッセージ（正常時はnull）
String? validateReorder({
  required List<({String id, int sortOrder})> items,
  required int expectedCount,
}) {
  // ID数チェック
  if (items.length != expectedCount) {
    return '並び替え対象のID数が不正です';
  }

  // 連番チェック
  final orders = items.map((e) => e.sortOrder).toList()..sort();
  for (var i = 0; i < orders.length; i++) {
    if (orders[i] != i) {
      return '表示順は0からの連番で指定してください（0, 1, 2, ...）';
    }
  }

  return null;
}
