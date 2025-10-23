# ベイズ推定実装ガイド

タグ影響分析のベイズ推定実装詳細。

---

## 概要

各タグがコンディションに与える影響を、**Normal-Normal共役事前分布**によるベイズ推定で定量化する。

### 目的

- タグ使用後の翌日以降のコンディション変化から、タグの寄与度を推定
- データが少ない場合でも、事前分布により安定した推定を実現
- 95%信用区間により、推定の不確実性を可視化

---

## 実装方針

### 使用パッケージ

```yaml
dependencies:
  statistics: ^1.2.0
```

```dart
import 'dart:math';
import 'package:statistics/statistics.dart';
```

---

## 実装コード

### BayesianEstimator クラス

**ファイル:** `lib/domain/services/bayesian_estimator.dart`

```dart
import 'dart:math';
import 'package:statistics/statistics.dart';

/// タグ影響のベイズ推定
///
/// Normal-Normal共役事前分布を使用して、タグがコンディションに与える影響を推定する。
///
/// 使用例:
/// ```dart
/// final result = BayesianEstimator.estimate(
///   observations: [0.5, 1.0, 0.3, -0.2],
/// );
/// print('寄与度: ${result.posteriorMean}');
/// print('信用区間: [${result.lowerBound}, ${result.upperBound}]');
/// ```
class BayesianEstimator {
  /// Normal-Normal共役事前分布によるベイズ更新
  ///
  /// [observations]: 観測データ（タグ使用後の翌日以降のコンディション、重み付き）
  /// [priorMean]: 事前平均（デフォルト: 0、タグの影響なしを仮定）
  /// [priorVariance]: 事前分散（デフォルト: 1）
  /// [priorSamples]: 仮想サンプル数（デフォルト: 5、事前情報の強さ）
  ///
  /// 返り値: ベイズ推定結果（事後平均、事後分散、信用区間）
  ///
  /// 注意点:
  /// - 観測数が少ない場合、事前分布の影響が大きくなり0に近づく（保守的な推定）
  /// - 観測数が増えるほど、データに基づく推定となる
  static BayesianEstimationResult estimate({
    required List<double> observations,
    double priorMean = 0,
    double priorVariance = 1,
    int priorSamples = 5,
  }) {
    // データ不足の場合は事前分布をそのまま返す
    if (observations.isEmpty) {
      final margin = 1.96 * sqrt(priorVariance);
      return BayesianEstimationResult(
        posteriorMean: priorMean,
        posteriorVariance: priorVariance,
        lowerBound: priorMean - margin,
        upperBound: priorMean + margin,
        observationCount: 0,
      );
    }

    // 観測データの統計量
    final stats = observations.statistics;
    final obsMean = stats.mean;
    final obsCount = observations.length;

    // ベイズ更新（Normal-Normal共役）
    final totalSamples = priorSamples + obsCount;
    final posteriorMean =
        (priorMean * priorSamples + obsMean * obsCount) / totalSamples;

    // 事後分散（簡略化: サンプル数のみ考慮）
    final posteriorVariance = priorVariance / totalSamples;

    // 95%信用区間
    final margin = 1.96 * sqrt(posteriorVariance);
    final lowerBound = posteriorMean - margin;
    final upperBound = posteriorMean + margin;

    return BayesianEstimationResult(
      posteriorMean: posteriorMean,
      posteriorVariance: posteriorVariance,
      lowerBound: lowerBound,
      upperBound: upperBound,
      observationCount: obsCount,
    );
  }

  /// 信頼係数の計算
  ///
  /// 信用区間が基準平均からどれだけ離れているかを0〜1で返す。
  ///
  /// [lowerBound]: 信用区間の下限
  /// [upperBound]: 信用区間の上限
  /// [baselineMean]: 基準平均（通常は0）
  ///
  /// 返り値:
  /// - 1.0 (100%): 信用区間が完全に基準から外れている（影響が明確）
  /// - 0.0 (0%): 信用区間が完全に基準と重なる（影響が不確実）
  static double calculateCredibility({
    required double lowerBound,
    required double upperBound,
    double baselineMean = 0,
  }) {
    // 信用区間が基準平均を含まない場合は100%
    if (upperBound < baselineMean || lowerBound > baselineMean) {
      return 1.0;
    }

    // 信用区間の幅
    final intervalWidth = upperBound - lowerBound;
    if (intervalWidth == 0) return 0.0;

    // 基準平均との重なり部分
    final overlapStart = max(lowerBound, baselineMean);
    final overlapEnd = min(upperBound, baselineMean);
    final overlapWidth = max(0.0, overlapEnd - overlapStart);

    // 重ならない割合を信頼度とする
    return 1.0 - (overlapWidth / intervalWidth);
  }
}

/// ベイズ推定の結果
class BayesianEstimationResult {
  /// 事後平均（タグの寄与度スコア）
  final double posteriorMean;

  /// 事後分散
  final double posteriorVariance;

  /// 95%信用区間の下限
  final double lowerBound;

  /// 95%信用区間の上限
  final double upperBound;

  /// 観測データ数
  final int observationCount;

  const BayesianEstimationResult({
    required this.posteriorMean,
    required this.posteriorVariance,
    required this.lowerBound,
    required this.upperBound,
    required this.observationCount,
  });

  /// データが十分か（3件以上）
  bool get hasSufficientData => observationCount >= 3;

  @override
  String toString() {
    return 'BayesianEstimationResult('
        'posteriorMean: $posteriorMean, '
        'credibleInterval: [$lowerBound, $upperBound], '
        'observations: $observationCount)';
  }
}
```

---

## ユニットテスト

**ファイル:** `test/domain/services/bayesian_estimator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker/domain/services/bayesian_estimator.dart';

void main() {
  group('BayesianEstimator', () {
    test('データなしの場合は事前分布を返す', () {
      final result = BayesianEstimator.estimate(observations: []);

      expect(result.posteriorMean, 0.0);
      expect(result.posteriorVariance, 1.0);
      expect(result.observationCount, 0);
      expect(result.hasSufficientData, false);
    });

    test('正の影響があるタグの推定', () {
      // タグ使用後、翌日のコンディションが平均+1.5改善
      final observations = [1.5, 1.8, 1.2, 1.6, 1.4, 1.7];

      final result = BayesianEstimator.estimate(observations: observations);

      // 事後平均は観測平均に近づく（事前分布の影響で少し0に引き寄せられる）
      expect(result.posteriorMean, greaterThan(1.0));
      expect(result.posteriorMean, lessThan(1.5));
      expect(result.hasSufficientData, true);
    });

    test('負の影響があるタグの推定', () {
      // タグ使用後、翌日のコンディションが平均-1.0悪化
      final observations = [-0.8, -1.2, -1.1, -0.9, -1.0];

      final result = BayesianEstimator.estimate(observations: observations);

      expect(result.posteriorMean, lessThan(0));
      expect(result.upperBound, lessThan(0)); // 信用区間上限も負
    });

    test('影響が不明確なタグの推定', () {
      // データが少なく、ばらつきが大きい
      final observations = [0.5, -0.3];

      final result = BayesianEstimator.estimate(observations: observations);

      // 事前分布の影響で0に近づく
      expect(result.posteriorMean.abs(), lessThan(0.5));
      expect(result.hasSufficientData, false);
    });

    test('信頼係数の計算: 信用区間が基準から完全に外れている', () {
      final credibility = BayesianEstimator.calculateCredibility(
        lowerBound: 0.5,
        upperBound: 1.5,
        baselineMean: 0,
      );

      expect(credibility, 1.0);
    });

    test('信頼係数の計算: 信用区間が基準を含む', () {
      final credibility = BayesianEstimator.calculateCredibility(
        lowerBound: -0.5,
        upperBound: 0.5,
        baselineMean: 0,
      );

      expect(credibility, lessThan(1.0));
      expect(credibility, greaterThan(0.0));
    });
  });
}
```

---

## 使用方法

### 分析画面での使用例

```dart
// 1. タグが付いた日を特定
final tagDates = trackRepository
    .searchTracks(tagIds: [tagId])
    .map((track) => track.recordedAt.toJstDate())
    .toSet();

// 2. 翌日以降のコンディションを収集（重み付き）
final observations = <double>[];
for (final date in tagDates) {
  // 翌日（重み1.0）
  final day1 = dailyRepository.findDaily(date.add(Duration(days: 1)));
  if (day1 != null) observations.add(day1.condition * 1.0);

  // 翌々日（重み0.67）
  final day2 = dailyRepository.findDaily(date.add(Duration(days: 2)));
  if (day2 != null) observations.add(day2.condition * 0.67);

  // 3日後（重み0.5）
  final day3 = dailyRepository.findDaily(date.add(Duration(days: 3)));
  if (day3 != null) observations.add(day3.condition * 0.5);
}

// 3. ベイズ推定
final result = BayesianEstimator.estimate(observations: observations);

// 4. 信頼係数
final credibility = BayesianEstimator.calculateCredibility(
  lowerBound: result.lowerBound,
  upperBound: result.upperBound,
);

// 5. UI表示
if (!result.hasSufficientData) {
  print('データ不足（観測: ${result.observationCount}件）');
} else {
  print('寄与度: ${result.posteriorMean.toStringAsFixed(2)}');
  print('信用区間: [${result.lowerBound.toStringAsFixed(2)}, ${result.upperBound.toStringAsFixed(2)}]');
  print('信頼係数: ${(credibility * 100).toStringAsFixed(0)}%');
}
```

---

## パラメータチューニング

### 事前分布のパラメータ

デフォルト値は以下の理由で設定：

- **事前平均 = 0**: タグの影響がないことを仮定（中立的な事前分布）
- **事前分散 = 1**: コンディションの範囲（-2〜2）を考慮した適度な不確実性
- **仮想サンプル数 = 5**: データが少ない場合に過学習を防ぐための適度な事前情報

### 調整が必要なケース

1. **保守的な推定にしたい場合**: 仮想サンプル数を増やす（10〜20）
2. **データをより重視したい場合**: 仮想サンプル数を減らす（2〜3）
3. **異なる事前仮定**: 事前平均を変更（例: 薬物タグは事前平均 +0.5）

---

## 制約と注意点

1. **データ不足の扱い**:
   - 観測数3件未満は「データ不足」として表示抑制
   - UI側で適切にフィードバック

2. **重み付けの妥当性**:
   - 翌日1.0、翌々日0.67、3日後0.5は経験的な値
   - 必要に応じて調整可能

3. **分散の簡略化**:
   - 現在の実装は観測データの分散を考慮していない
   - より厳密な推定が必要な場合は、観測分散を組み込んだ式に拡張

---

## 参考文献

- [Bayesian Statistics](https://en.wikipedia.org/wiki/Bayesian_statistics)
- [Normal-Normal Conjugate Prior](https://en.wikipedia.org/wiki/Conjugate_prior#Table_of_conjugate_distributions)
- ui_behavior.md の計算ロジック（269-316行）
