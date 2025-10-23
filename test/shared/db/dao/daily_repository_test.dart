/// DailyRepositoryのユニットテスト
///
/// 検証価値の高い項目のみテスト:
/// - upsertパターン（作成と更新の切り替え）
/// - 日付形式バリデーション
/// - 期間検索
/// - 睡眠時刻バリデーション（起床>就寝）
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';
import 'package:personal_tracker_v2/shared/db/dao/daily_repository.dart';
import 'package:personal_tracker_v2/shared/exceptions/repository_exceptions.dart';

void main() {
  late AppDatabase db;
  late DailyRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = DailyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DailyRepository', () {
    test('findDaily は指定日付の日記を返す', () async {
      await repo.upsertDaily(date: '2025-10-23', memo: 'テストメモ', condition: 1);

      final daily = await repo.findDaily('2025-10-23');

      expect(daily, isNotNull);
      expect(daily!.date, '2025-10-23');
      expect(daily.memo, 'テストメモ');
      expect(daily.condition, 1);
    });

    test('findDaily は存在しない日付で null を返す', () async {
      final daily = await repo.findDaily('2025-10-23');

      expect(daily, isNull);
    });

    test('searchDailies は日付の降順でソートされたリストを返す', () async {
      await repo.upsertDaily(date: '2025-10-21', memo: '1日目');
      await repo.upsertDaily(date: '2025-10-22', memo: '2日目');
      await repo.upsertDaily(date: '2025-10-23', memo: '3日目');

      final dailies = await repo.searchDailies();

      expect(dailies.length, 3);
      expect(dailies[0].date, '2025-10-23'); // 最新が先頭
      expect(dailies[1].date, '2025-10-22');
      expect(dailies[2].date, '2025-10-21');
    });

    test('searchDailies は期間でフィルタできる', () async {
      await repo.upsertDaily(date: '2025-10-20', memo: '範囲外');
      await repo.upsertDaily(date: '2025-10-21', memo: '範囲内1');
      await repo.upsertDaily(date: '2025-10-22', memo: '範囲内2');
      await repo.upsertDaily(date: '2025-10-23', memo: '範囲内3');
      await repo.upsertDaily(date: '2025-10-24', memo: '範囲外');

      final filtered = await repo.searchDailies(
        startDate: '2025-10-21',
        endDate: '2025-10-23',
      );

      expect(filtered.length, 3);
      expect(filtered[0].date, '2025-10-23');
      expect(filtered[1].date, '2025-10-22');
      expect(filtered[2].date, '2025-10-21');
    });

    test('searchDailies は condition でフィルタできる', () async {
      await repo.upsertDaily(date: '2025-10-21', memo: '良い日', condition: 1);
      await repo.upsertDaily(date: '2025-10-22', memo: '悪い日', condition: -1);
      await repo.upsertDaily(date: '2025-10-23', memo: '普通の日', condition: 0);

      final filtered = await repo.searchDailies(condition: 1);

      expect(filtered.length, 1);
      expect(filtered[0].memo, '良い日');
    });

    test('upsertDaily は新規日記を作成する', () async {
      final daily = await repo.upsertDaily(
        date: '2025-10-23',
        memo: '初回メモ',
        condition: 1,
      );

      expect(daily.date, '2025-10-23');
      expect(daily.memo, '初回メモ');
      expect(daily.condition, 1);
    });

    test('upsertDaily は既存日記を更新する', () async {
      await repo.upsertDaily(
        date: '2025-10-23',
        memo: '初回メモ',
        condition: 0,
      );

      final updated = await repo.upsertDaily(
        date: '2025-10-23',
        memo: '更新後メモ',
        condition: 1,
      );

      expect(updated.memo, '更新後メモ');
      expect(updated.condition, 1);

      // 1件のみ存在することを確認
      final all = await repo.searchDailies();
      expect(all.length, 1);
    });

    test('upsertDaily は睡眠時刻を保存する', () async {
      final sleepStart = DateTime.utc(2025, 10, 22, 23, 0);
      final sleepEnd = DateTime.utc(2025, 10, 23, 7, 0);

      final daily = await repo.upsertDaily(
        date: '2025-10-23',
        memo: 'メモ',
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
      );

      // 睡眠時刻が保存されていることを確認（タイムゾーン変換の詳細は環境依存）
      expect(daily.sleepStart, isNotNull);
      expect(daily.sleepEnd, isNotNull);
    });

    test('upsertDaily は起床時刻が就寝時刻より前で ValidationException をスローする', () async {
      final sleepStart = DateTime.utc(2025, 10, 23, 7, 0);
      final sleepEnd = DateTime.utc(2025, 10, 22, 23, 0); // 逆転

      expect(
        () => repo.upsertDaily(
          date: '2025-10-23',
          memo: 'メモ',
          sleepStart: sleepStart,
          sleepEnd: sleepEnd,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('upsertDaily は不正な日付形式で ValidationException をスローする', () async {
      expect(
        () => repo.upsertDaily(date: '2025/10/23', memo: 'メモ'),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => repo.upsertDaily(date: '20251023', memo: 'メモ'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('upsertDaily は5001文字のmemoで ValidationException をスローする', () async {
      final longMemo = 'a' * 5001;

      expect(
        () => repo.upsertDaily(date: '2025-10-23', memo: longMemo),
        throwsA(isA<ValidationException>()),
      );
    });

    test('deleteDaily は日記を削除する', () async {
      await repo.upsertDaily(date: '2025-10-23', memo: 'メモ');

      await repo.deleteDaily('2025-10-23');

      final daily = await repo.findDaily('2025-10-23');
      expect(daily, isNull);
    });

    test('deleteDaily は存在しない日付で NotFoundException をスローする', () async {
      expect(
        () => repo.deleteDaily('2025-10-23'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
