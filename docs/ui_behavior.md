# UI挙動の設計意図

各画面のコンセプトとUX方針。

---

## Track画面

### コンセプト
**Slackのメッセージストリーム**

### レイアウト
- 上から下にトラックが時系列で流れる
- 新しい記録ほど下に表示される
- 過去を遡るには**上方向へ無限スクロール**

### 実装方針
```dart
// ListView.builderで実装
// 上スクロールを検知してページング
ListView.builder(
  reverse: false, // 通常の上→下スクロール
  itemCount: tracks.length,
  itemBuilder: (context, index) {
    return TrackCard(track: tracks[index]);
  },
)

// 上端到達時に過去データを追加読み込み
```

### UI要素

#### 左サイドバー
- **検索入力ボックス**: 「メモ・タグで検索」
  - メモの部分一致検索
  - 位置: Tagsメニューの下、コンディションフィルターの上
- **コンディションフィルター**: 5つの円形ボタン（-2〜2）
- **タグフィルター**: カテゴリごとにグループ化されたチェックボックスリスト

#### 各トラックカード
- 記録日時（JST表示、`recordedAt` を表示）
- メモ
- コンディション（-2〜2のアイコン表示）
- タグ（カテゴリ色付きチップ、削除済みタグは非表示）
- 編集・削除ボタン

#### トラック作成/編集ダイアログ
- 記録日時の選択UI（DateTimePicker）
  - デフォルトは現在時刻
  - 過去日時の設定可能

### 参考スクリーンショット
`ui_images/track.png`

---

## Daily画面

### コンセプト
**Googleカレンダー風の日記管理**

### 表示モード

#### 1. リストビュー
- 上から下に日記が流れる形式
- カード形式で1日1件表示
- 上方向への無限スクロールで過去を遡る

#### 2. カレンダービュー
- 月表示でコンディションを色で可視化
- 各日付のセルにコンディションアイコン表示
- 日付クリックで詳細表示・編集

### 実装方針
```dart
// TabBarで切り替え
TabBar(
  tabs: [
    Tab(text: 'リスト', icon: Icon(Icons.list)),
    Tab(text: 'カレンダー', icon: Icon(Icons.calendar_month)),
  ],
)

// リストビュー
ListView.builder(
  itemBuilder: (context, index) {
    return DailyCard(daily: dailies[index]);
  },
)

// カレンダービュー
TableCalendar(
  calendarFormat: CalendarFormat.month,
  onDaySelected: (selectedDay, focusedDay) {
    // 日記編集画面へ遷移
  },
)
```

### UI要素（リストビュー）
- 各日記カード:
  - 日付（YYYY-MM-DD）
  - コンディション
  - 睡眠時間（sleepEnd - sleepStart）
  - メモ（折りたたみ可能）
  - 編集ボタン

### UI要素（カレンダービュー）
- 各日付セル:
  - コンディションアイコン（色分け）
  - 日記があるかのインジケーター

### 参考スクリーンショット
- リストビュー: `ui_images/daily-list.png`
- カレンダービュー: `ui_images/daily.png`

---

## Tags画面

### コンセプト
**階層的なカテゴリ/タグ管理**

### レイアウト
- カテゴリごとにセクション分け
- 各セクション内にタグ一覧
- 折りたたみ可能なアコーディオン形式

### UI要素

#### カテゴリヘッダー
- カテゴリカラーの丸アイコン
- カテゴリ名
- タグ数（例: "服薬 (3)"）
- 編集・アーカイブ・折りたたみボタン

#### タグ一覧
- カテゴリカラーの淡色背景
- タグ名（カテゴリカラーのテキスト）
- 上下移動ボタン（横並び）
- 編集・アーカイブボタン

#### タグ追加ボタン
- 各カテゴリセクション内に配置
- "+ タグ追加" ボタン

### 操作フロー

#### カテゴリ追加
1. 右上の「+ カテゴリ 追加」ボタンをタップ
2. ダイアログ表示:
   - カテゴリ名入力（文字数カウンター表示）
   - 8色のカラーパレットから選択
   - プレビュー表示
   - キャンセル/追加ボタン

#### タグ追加
1. カテゴリセクション内の「+ タグ追加」ボタンをタップ
2. ダイアログ表示:
   - タイトル: "タグ追加 - {カテゴリ名}"
   - タグ名入力
   - キャンセル/追加ボタン

#### 並び替え
- 各タグの上下矢印ボタンで1つずつ移動
- アーカイブ表示をオンにして全タグを表示することを推奨

### ボタン配置

#### 通常のTags画面
- **カテゴリ**: 編集（ペン）、アーカイブボタン
- **タグ**: 上下移動、編集（ペン）、アーカイブボタン

#### アーカイブ画面
- **画面遷移**: 左下の「Archived」リンクをクリック
- **カテゴリ**: 編集（ペン）、レストア（復元アイコン ↶）、削除ボタン
- **タグ**: レストア（復元アイコン ↶）、削除ボタン
- **削除時の挙動**: 全Trackから該当タグIDを即座にクリーンアップ

### 参考スクリーンショット
- メイン画面: `ui_images/tags.png`
- カテゴリ追加ダイアログ: `ui_images/tags-add.png`

---

## Analysis画面

### コンセプト
**データの可視化と傾向分析**

---

### 1. コンディション推移

#### 表示内容
- 期間選択UI:
  - ボタン切り替え: 1d（1日）/ 1w（1週間）/ 1m（1ヶ月）
  - 日付範囲指定: 開始日〜終了日
- **積み上げ棒グラフ**（日付別のコンディション分布）
- 凡例: +2（青）、+1（緑）、基準±0（灰）、-1（オレンジ）、-2（赤）

#### データソース
- **1d（日単位）**: Trackのコンディションを集計
  - 同じ日の複数トラックをコンディション別にカウント
- **1w / 1m（週/月単位）**: Dailyのコンディションを集計
  - 各日の日記コンディションをカウント

#### 実装
```dart
// 1d: Track の集計
Map<String, Map<int, int>> dailyTrackConditions;
// key: 日付(YYYY-MM-DD), value: {condition: count}

// 1w/1m: Daily の集計
Map<String, Map<int, int>> dailyConditions;
// key: 日付(YYYY-MM-DD), value: {condition: count}
```

---

### 2. 睡眠分析

#### 表示内容
- 中心時刻の入力フィールド（例: 3時）
- **複合グラフ**:
  - **縦棒グラフ（薄青）**: 睡眠時間の範囲
    - 上端: 起床時刻
    - 下端: 就寝時刻
  - **折れ線グラフ（赤線）**: 純粋な睡眠時間（時間数）
    - ドット付き
    - 記録がない日は点線で繋ぐ
  - **基準線（点線）**: 中心時刻の水平線

#### データ処理
```dart
// Daily から取得
for (daily in dailies) {
  if (daily.sleepStart != null && daily.sleepEnd != null) {
    // 就寝時刻（Y軸下端）
    double sleepStartHour = toHourOfDay(daily.sleepStart);

    // 起床時刻（Y軸上端）
    double sleepEndHour = toHourOfDay(daily.sleepEnd);

    // 睡眠時間（折れ線グラフ）
    double sleepDuration = daily.sleepEnd.difference(daily.sleepStart).inHours;
  }
}

// 記録がない日は null → グラフで点線表示
```

---

### 3. タグ影響ベイズ推定

#### 表示内容
- タイトル: 「タグ影響ベイズ推定（日単位の寄与度）」
- 「前提条件」ボタン → 設定ダイアログ表示
- セクション分け:
  - **プラス寄与（コンディション向上）**: 緑背景
  - **マイナス寄与（コンディション低下）**: 赤背景
- 各タグの表示:
  - タグ名（カテゴリ色の背景）
  - 観測回数（例: 「7回 観測21件」）
  - 寄与度スコア（例: +0.64）
  - 横棒グラフ（緑/赤のプログレスバー）
  - 95%信用区間（例: 0.21〜1.06）
  - 信頼係数（例: 100%）

#### ベイズ推定パラメータ

**基準平均（全タグ加重平均）:**
- 全データの平均コンディション（例: -0.05）

**事前分布パラメータ:**
- 事前平均: 0
- 仮想サンプル数: 5
- 事前分散: 1

**ラグ重み（時間減衰）:**
- 翌日: 1.0（100%）
- 翌々日: 0.67（67%）
- 3日後: 0.5（50%）

#### 計算ロジック

```dart
// 各タグについて
for (tag in tags) {
  // 1. タグが付いた日を特定
  List<DateTime> tagDates = getTrackDatesWithTag(tag.id);

  // 2. 翌日以降のコンディションを収集（重み付き）
  List<double> observations = [];
  for (date in tagDates) {
    // 翌日のコンディション（重み1.0）
    if (dailyExists(date + 1day)) {
      observations.add(getDaily(date + 1day).condition * 1.0);
    }
    // 翌々日のコンディション（重み0.67）
    if (dailyExists(date + 2days)) {
      observations.add(getDaily(date + 2days).condition * 0.67);
    }
    // 3日後のコンディション（重み0.5）
    if (dailyExists(date + 3days)) {
      observations.add(getDaily(date + 3days).condition * 0.5);
    }
  }

  // 3. ベイズ更新（正規分布）
  double priorMean = 0;
  double priorVariance = 1;
  int priorSamples = 5;

  double observationMean = observations.mean();
  int observationCount = observations.length;

  // 事後平均（寄与度スコア）
  double posteriorMean =
    (priorMean * priorSamples + observationMean * observationCount) /
    (priorSamples + observationCount);

  // 事後分散
  double posteriorVariance =
    priorVariance / (priorSamples + observationCount);

  // 95%信用区間
  double margin = 1.96 * sqrt(posteriorVariance);
  double lowerBound = posteriorMean - margin;
  double upperBound = posteriorMean + margin;

  // 信頼係数（信用区間が基準平均を含まない程度）
  double credibility = calculateCredibility(lowerBound, upperBound, baselineMean);
}
```

**観測回数の意味:**
- 「7回 観測21件」= タグが付いた日が7日、翌日以降の観測データが21件

**信頼係数の計算:**
```dart
double calculateCredibility(double lowerBound, double upperBound, double baselineMean) {
  // 信用区間が基準平均（0）を含まない場合は100%
  if (upperBound < baselineMean || lowerBound > baselineMean) {
    return 1.0; // 100%
  }

  // 信用区間の幅
  double intervalWidth = upperBound - lowerBound;

  // 基準平均との重なり部分
  double overlapStart = max(lowerBound, baselineMean);
  double overlapEnd = min(upperBound, baselineMean);
  double overlapWidth = max(0, overlapEnd - overlapStart);

  // 重ならない割合を信頼度とする
  return 1.0 - (overlapWidth / intervalWidth);
}
```

**データ不足の扱い:**
- 観測数が3件未満の場合は「データ不足」として表示を抑制
- UIに「このタグはデータが不足しています（観測: 2件）」と表示

---

### 実装ライブラリ

**グラフ描画:**
- `fl_chart` パッケージ
- 積み上げ棒グラフ（BarChart）
- 複合グラフ（BarChart + LineChart）
- 横棒グラフ（LinearProgressIndicator / カスタムウィジェット）

**統計計算:**
- `dart:math`: sqrt, pow
- `statistics ^1.2.0`: mean, standardDeviation
- ベイズ推定は自前実装（`lib/domain/services/bayesian_estimator.dart`）

### 参考スクリーンショット
- コンディション推移: `ui_images/analysis1.png`
- 睡眠分析 + タグ影響: `ui_images/analysis2.png`
- タグ影響詳細: `ui_images/analysis3.png`
- ベイズ設定ダイアログ: `ui_images/analysis-bayes-condition.png`

---

## 共通UI要素

### コンディション表示
コンディション値を視覚的に表現：

```dart
const conditionIcons = {
  -2: {'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red},
  -1: {'icon': Icons.sentiment_dissatisfied, 'color': Colors.orange},
   0: {'icon': Icons.sentiment_neutral, 'color': Colors.grey},
   1: {'icon': Icons.sentiment_satisfied, 'color': Colors.lightGreen},
   2: {'icon': Icons.sentiment_very_satisfied, 'color': Colors.green},
};
```

### タグチップ
カテゴリカラーを反映したチップ：

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: categoryColor.withOpacity(0.2), // 20%透明度
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    tagName,
    style: TextStyle(
      color: categoryColor, // カテゴリカラー
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### 日時表示
- 作成日時: JST変換して表示（例: "2025-10-23 14:30"）
- 相対時間表示も検討（例: "3時間前"）
