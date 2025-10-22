# バリデーションルール定義

各フィールドのバリデーション仕様とエラーメッセージ。

---

## Category バリデーション

### name（カテゴリ名）

**制約:**
- 必須
- 1文字以上50文字以内
- 既存のカテゴリ名と重複不可

**エラーメッセージ:**

```dart
// 空文字・null
"カテゴリ名を入力してください"

// 長さ超過
"カテゴリ名は50文字以内で入力してください"

// 重複
"このカテゴリ名は既に使用されています"
```

**実装例:**

```dart
String? validateCategoryName(String? value, {required List<String> existingNames}) {
  if (value == null || value.trim().isEmpty) {
    return 'カテゴリ名を入力してください';
  }
  if (value.length > 50) {
    return 'カテゴリ名は50文字以内で入力してください';
  }
  if (existingNames.contains(value.trim())) {
    return 'このカテゴリ名は既に使用されています';
  }
  return null;
}
```

---

### color（カラーコード）

**制約:**
- 必須
- #RRGGBB形式（正規表現: `^#[0-9A-Fa-f]{6}$`）

**エラーメッセージ:**

```dart
// 空文字・null
"カラーコードを入力してください"

// 形式不正
"#RRGGBB 形式で入力してください（例: #FF5733）"
```

**実装例:**

```dart
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
```

---

### sortOrder（表示順）

**制約:**
- 0以上の整数
- 全カテゴリで重複しない連番

**エラーメッセージ:**

```dart
// 範囲外
"表示順は0以上の整数を指定してください"

// 重複
"この表示順は既に使用されています"
```

---

## Tag バリデーション

### name（タグ名）

**制約:**
- 必須
- 1文字以上50文字以内
- 同一カテゴリ内で重複不可

**エラーメッセージ:**

```dart
// 空文字・null
"タグ名を入力してください"

// 長さ超過
"タグ名は50文字以内で入力してください"

// カテゴリ内重複
"このタグ名は既に使用されています"
```

**実装例:**

```dart
String? validateTagName(
  String? value, {
  required String categoryId,
  required List<String> existingNamesInCategory,
}) {
  if (value == null || value.trim().isEmpty) {
    return 'タグ名を入力してください';
  }
  if (value.length > 50) {
    return 'タグ名は50文字以内で入力してください';
  }
  if (existingNamesInCategory.contains(value.trim())) {
    return 'このタグ名は既に使用されています';
  }
  return null;
}
```

---

### sortOrder（表示順）

**制約:**
- 0以上の整数
- 同一カテゴリ内で重複しない連番

**エラーメッセージ:**

```dart
// カテゴリ内重複
"この表示順は既に使用されています"
```

---

## Track バリデーション

### memo（メモ）

**制約:**
- 任意（nullable）
- 最大1000文字

**エラーメッセージ:**

```dart
// 長さ超過
"メモは1000文字以内で入力してください"
```

**実装例:**

```dart
String? validateTrackMemo(String? value) {
  if (value != null && value.length > 1000) {
    return 'メモは1000文字以内で入力してください';
  }
  return null;
}
```

---

### condition（コンディション）

**制約:**
- -2〜2の整数
- デフォルト値: 0

**エラーメッセージ:**

```dart
// 範囲外
"コンディションは-2から2の間で選択してください"
```

**実装例:**

```dart
String? validateCondition(int? value) {
  if (value == null || value < -2 || value > 2) {
    return 'コンディションは-2から2の間で選択してください';
  }
  return null;
}
```

---

### tagIds（タグIDリスト）

**制約:**
- 任意（空配列可）
- 存在しないIDは保存時に無視（エラーにしない）

**補足:**
- バリデーションエラーは発生させない
- Repository層で存在チェックを行い、存在しないIDを除外

---

## Daily バリデーション

### date（日付）

**制約:**
- 必須
- YYYY-MM-DD形式
- 1日1件のみ（主キー）

**エラーメッセージ:**

```dart
// 形式不正
"日付はYYYY-MM-DD形式で指定してください"

// 重複
"この日付の日記は既に存在します"
```

---

### memo（日記）

**制約:**
- 任意（nullable）
- 最大5000文字

**エラーメッセージ:**

```dart
// 長さ超過
"日記は5000文字以内で入力してください"
```

**実装例:**

```dart
String? validateDailyMemo(String? value) {
  if (value != null && value.length > 5000) {
    return '日記は5000文字以内で入力してください';
  }
  return null;
}
```

---

### condition（コンディション）

Track と同じ制約。

---

### sleepStart / sleepEnd（睡眠時刻）

**制約:**
- 任意（nullable）
- DateTime型
- `sleepEnd` は `sleepStart` より後でなければならない

**エラーメッセージ:**

```dart
// 時刻逆転
"起床時刻は就寝時刻より後に設定してください"
```

**実装例:**

```dart
String? validateSleepTimes(DateTime? sleepStart, DateTime? sleepEnd) {
  if (sleepStart != null && sleepEnd != null) {
    if (sleepEnd.isBefore(sleepStart)) {
      return '起床時刻は就寝時刻より後に設定してください';
    }
  }
  return null;
}
```

---

## 並び替えバリデーション

### reorder（表示順一括更新）

**制約:**
- 指定ID数が対象レコード数と一致
- `sortOrder` が0からの連番（重複・抜け番禁止）

**エラーメッセージ:**

```dart
// ID数不一致
"並び替え対象のID数が不正です"

// 連番不正
"表示順は0からの連番で指定してください（0, 1, 2, ...）"

// ID未存在
"指定されたIDが存在しません: {id}"
```

**実装例:**

```dart
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
```

---

## カラーパレット定義

カテゴリ作成時に使用する色の選択肢。

```dart
const colorPresets = [
  {'name': '青', 'value': '#3B82F6'},
  {'name': '赤', 'value': '#EF4444'},
  {'name': '緑', 'value': '#10B981'},
  {'name': '黄', 'value': '#F59E0B'},
  {'name': '紫', 'value': '#8B5CF6'},
  {'name': 'ピンク', 'value': '#EC4899'},
  {'name': 'シアン', 'value': '#06B6D4'},
  {'name': 'オレンジ', 'value': '#F97316'},
];
```

**使用箇所:**
- カテゴリ追加ダイアログ
- カテゴリ編集ダイアログ
