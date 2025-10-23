/// 日記リポジトリ
///
/// 日記の CRUD 操作を提供する。
///
/// 使用例:
/// ```dart
/// final repo = DailyRepository(db);
/// final daily = await repo.findDaily('2025-10-23');
/// await repo.upsertDaily(
///   date: '2025-10-23',
///   memo: '今日は体調が良かった',
///   condition: 1,
/// );
/// ```
///
/// 注意点:
/// - 日付はYYYY-MM-DD形式（JST基準）
/// - 1日1件のみ（upsertで作成or更新）
/// - 睡眠時刻はUTC保存
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';
import '../../exceptions/repository_exceptions.dart';
import '../../validators/field_validators.dart';

/// 日記リポジトリ
class DailyRepository {
  final AppDatabase _db;

  DailyRepository(this._db);

  /// 指定日付の日記を取得
  ///
  /// パラメータ:
  /// - date: YYYY-MM-DD形式の日付
  ///
  /// 戻り値: 日記レコード（存在しない場合はnull）
  Future<DailyRecord?> findDaily(String date) async {
    // 日付形式バリデーション
    final dateError = validateDateFormat(date);
    if (dateError != null) {
      throw ValidationException(dateError, issues: {'date': [dateError]});
    }

    return await (_db.select(_db.dailies)..where((t) => t.date.equals(date))).getSingleOrNull();
  }

  /// 日記一覧を取得（期間指定）
  ///
  /// パラメータ:
  /// - startDate: 開始日（YYYY-MM-DD）
  /// - endDate: 終了日（YYYY-MM-DD）
  /// - condition: コンディションでフィルタ
  ///
  /// 戻り値: 日付の降順でソート済みの日記リスト
  Future<List<DailyRecord>> searchDailies({
    String? startDate,
    String? endDate,
    int? condition,
  }) async {
    // 日付形式バリデーション
    if (startDate != null) {
      final error = validateDateFormat(startDate);
      if (error != null) {
        throw ValidationException(error, issues: {'startDate': [error]});
      }
    }

    if (endDate != null) {
      final error = validateDateFormat(endDate);
      if (error != null) {
        throw ValidationException(error, issues: {'endDate': [error]});
      }
    }

    final query = _db.select(_db.dailies);

    // 期間フィルタ
    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate));
    }

    // conditionフィルタ
    if (condition != null) {
      query.where((t) => t.condition.equals(condition));
    }

    // 降順ソート
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);

    return await query.get();
  }

  /// 日記を作成または更新
  ///
  /// パラメータ:
  /// - date: 日付（YYYY-MM-DD）
  /// - memo: 日記内容（最大5000文字、省略可）
  /// - condition: コンディション（-2〜2、デフォルト: 0）
  /// - sleepStart: 就寝時刻（UTC、省略可）
  /// - sleepEnd: 起床時刻（UTC、省略可）
  ///
  /// 処理:
  /// - 指定日付の日記が存在すれば更新、なければ作成
  /// - updatedAtを現在時刻に更新
  ///
  /// 例外:
  /// - ValidationException: バリデーションエラー
  Future<DailyRecord> upsertDaily({
    required String date,
    String? memo,
    int condition = 0,
    DateTime? sleepStart,
    DateTime? sleepEnd,
  }) async {
    // バリデーション
    final dateError = validateDateFormat(date);
    if (dateError != null) {
      throw ValidationException(dateError, issues: {'date': [dateError]});
    }

    final memoError = validateDailyMemo(memo);
    if (memoError != null) {
      throw ValidationException(memoError, issues: {'memo': [memoError]});
    }

    final conditionError = validateCondition(condition);
    if (conditionError != null) {
      throw ValidationException(conditionError, issues: {'condition': [conditionError]});
    }

    final sleepError = validateSleepTimes(sleepStart, sleepEnd);
    if (sleepError != null) {
      throw ValidationException(sleepError, issues: {'sleep': [sleepError]});
    }

    final now = DateTime.now().toUtc();

    // 既存レコード確認
    final existing = await findDaily(date);

    if (existing == null) {
      // 新規作成
      final companion = DailiesCompanion.insert(
        date: date,
        memo: Value(memo),
        condition: Value(condition),
        sleepStart: Value(sleepStart),
        sleepEnd: Value(sleepEnd),
        createdAt: now,
        updatedAt: now,
      );

      await _db.into(_db.dailies).insert(companion);
    } else {
      // 更新
      final companion = DailiesCompanion(
        memo: Value(memo),
        condition: Value(condition),
        sleepStart: Value(sleepStart),
        sleepEnd: Value(sleepEnd),
        updatedAt: Value(now),
      );

      await (_db.update(_db.dailies)..where((t) => t.date.equals(date))).write(companion);
    }

    // 作成/更新したレコードを返す
    return (await (_db.select(_db.dailies)..where((t) => t.date.equals(date))).getSingle());
  }

  /// 日記を削除
  ///
  /// パラメータ:
  /// - date: 削除対象の日付（YYYY-MM-DD）
  ///
  /// 例外:
  /// - NotFoundException: 指定日付の日記が存在しない
  Future<void> deleteDaily(String date) async {
    final count = await (_db.delete(_db.dailies)..where((t) => t.date.equals(date))).go();
    if (count == 0) {
      throw NotFoundException('日記が見つかりません: $date');
    }
  }
}
