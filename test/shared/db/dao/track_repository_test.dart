/// TrackRepositoryのユニットテスト
///
/// 検証価値の高い項目のみテスト:
/// - 存在しないtagIdの自動除外
/// - ページング（before）動作
/// - フィルター（memo, tagIds, condition）動作
/// - バリデーション（memo長さ、condition範囲）
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_tracker_v2/shared/db/database.dart';
import 'package:personal_tracker_v2/shared/db/dao/category_repository.dart';
import 'package:personal_tracker_v2/shared/db/dao/tag_repository.dart';
import 'package:personal_tracker_v2/shared/db/dao/track_repository.dart';
import 'package:personal_tracker_v2/shared/exceptions/repository_exceptions.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categoryRepo;
  late TagRepository tagRepo;
  late TrackRepository trackRepo;

  setUp(() {
    db = AppDatabase.memory();
    categoryRepo = CategoryRepository(db);
    tagRepo = TagRepository(db);
    trackRepo = TrackRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TrackRepository', () {
    test('searchTracks は recordedAt 降順でソートされたリストを返す', () async {
      final now = DateTime.now().toUtc();
      await trackRepo.createTrack(memo: '1番目', recordedAt: now.subtract(const Duration(hours: 2)));
      await trackRepo.createTrack(memo: '2番目', recordedAt: now.subtract(const Duration(hours: 1)));
      await trackRepo.createTrack(memo: '3番目', recordedAt: now);

      final tracks = await trackRepo.searchTracks();

      expect(tracks.length, 3);
      expect(tracks[0].memo, '3番目'); // 最新が先頭
      expect(tracks[1].memo, '2番目');
      expect(tracks[2].memo, '1番目');
    });

    test('searchTracks は before パラメータでページングできる', () async {
      final now = DateTime.now().toUtc();
      await trackRepo.createTrack(memo: '1番目', recordedAt: now.subtract(const Duration(hours: 3)));
      await trackRepo.createTrack(memo: '2番目', recordedAt: now.subtract(const Duration(hours: 2)));
      await trackRepo.createTrack(memo: '3番目', recordedAt: now.subtract(const Duration(hours: 1)));

      // 最新2件を取得
      final page1 = await trackRepo.searchTracks(limit: 2);
      expect(page1.length, 2);
      expect(page1[0].memo, '3番目');
      expect(page1[1].memo, '2番目');

      // beforeパラメータで過去を遡る
      final page2 = await trackRepo.searchTracks(limit: 2, before: page1.last.recordedAt);
      expect(page2.length, 1);
      expect(page2[0].memo, '1番目');
    });

    test('searchTracks は memoKeyword でフィルタできる', () async {
      await trackRepo.createTrack(memo: '頭痛がひどい');
      await trackRepo.createTrack(memo: '腹痛');
      await trackRepo.createTrack(memo: '頭が痛い');

      final filtered = await trackRepo.searchTracks(memoKeyword: '頭痛');

      expect(filtered.length, 1);
      expect(filtered[0].memo, '頭痛がひどい');
    });

    test('searchTracks は condition でフィルタできる', () async {
      await trackRepo.createTrack(memo: '良い日', condition: 1);
      await trackRepo.createTrack(memo: '悪い日', condition: -1);
      await trackRepo.createTrack(memo: '普通の日', condition: 0);

      final filtered = await trackRepo.searchTracks(condition: 1);

      expect(filtered.length, 1);
      expect(filtered[0].memo, '良い日');
    });

    test('searchTracks は tagIds でフィルタできる（OR条件）', () async {
      final cat = await categoryRepo.createCategory(name: '薬', color: '#3B82F6');
      final tag1 = await tagRepo.createTag(categoryId: cat.id, name: 'デパス');
      final tag2 = await tagRepo.createTag(categoryId: cat.id, name: 'ロキソニン');
      final tag3 = await tagRepo.createTag(categoryId: cat.id, name: 'ガスター');

      await trackRepo.createTrack(memo: 'デパスを服用', tagIds: [tag1.id]);
      await trackRepo.createTrack(memo: 'ロキソニンを服用', tagIds: [tag2.id]);
      await trackRepo.createTrack(memo: 'デパスとガスター', tagIds: [tag1.id, tag3.id]);

      // tag1かtag3を含むトラックを検索
      final filtered = await trackRepo.searchTracks(tagIds: [tag1.id, tag3.id]);

      expect(filtered.length, 2);
      expect(filtered.any((t) => t.memo == 'デパスを服用'), true);
      expect(filtered.any((t) => t.memo == 'デパスとガスター'), true);
    });

    test('createTrack は存在しないtagIdを除外して保存する', () async {
      final cat = await categoryRepo.createCategory(name: '薬', color: '#3B82F6');
      final tag = await tagRepo.createTag(categoryId: cat.id, name: 'デパス');

      final track = await trackRepo.createTrack(
        memo: 'メモ',
        tagIds: [tag.id, 'nonexistent-id'],
      );

      expect(track.tagIds.length, 1);
      expect(track.tagIds[0], tag.id);
    });

    test('createTrack は1001文字のmemoで ValidationException をスローする', () async {
      final longMemo = 'a' * 1001;

      expect(
        () => trackRepo.createTrack(memo: longMemo),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createTrack は範囲外の condition で ValidationException をスローする', () async {
      expect(
        () => trackRepo.createTrack(condition: -3),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => trackRepo.createTrack(condition: 3),
        throwsA(isA<ValidationException>()),
      );
    });

    test('updateTrack はメモとコンディションを更新する', () async {
      final track = await trackRepo.createTrack(memo: '元のメモ', condition: 0);

      final updated = await trackRepo.updateTrack(
        id: track.id,
        memo: '更新後のメモ',
        condition: 1,
      );

      expect(updated.memo, '更新後のメモ');
      expect(updated.condition, 1);
    });

    test('updateTrack は存在しないIDで NotFoundException をスローする', () async {
      expect(
        () => trackRepo.updateTrack(id: 'nonexistent', memo: 'test'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('deleteTrack はトラックを削除する', () async {
      final track = await trackRepo.createTrack(memo: 'メモ');

      await trackRepo.deleteTrack(track.id);

      final tracks = await trackRepo.searchTracks();
      expect(tracks.length, 0);
    });
  });
}
