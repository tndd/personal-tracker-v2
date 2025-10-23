/// トラックリポジトリ
///
/// トラックの CRUD 操作を提供する。
///
/// 使用例:
/// ```dart
/// final repo = TrackRepository(db);
/// final tracks = await repo.searchTracks(limit: 50);
/// final newTrack = await repo.createTrack(
///   memo: '頭痛',
///   condition: -1,
///   tagIds: ['tag-id-1', 'tag-id-2'],
/// );
/// ```
///
/// 注意点:
/// - 存在しないtagIdは除外して保存
/// - ページング対応（beforeパラメータで過去を遡る）
/// - フィルター対応（memoKeyword, tagIds, condition）
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database.dart';
import '../tables.dart';
import '../../exceptions/repository_exceptions.dart';
import '../../validators/field_validators.dart';

/// トラックリポジトリ
class TrackRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  TrackRepository(this._db);

  /// トラック一覧を取得（ページング対応）
  ///
  /// パラメータ:
  /// - limit: 取得件数（デフォルト: 50）
  /// - before: この日時より前のレコードを取得（ページング用）
  /// - memoKeyword: メモの部分一致検索
  /// - tagIds: タグIDでフィルタ（OR条件）
  /// - condition: コンディションでフィルタ
  ///
  /// 戻り値: createdAtの降順でソート済みのトラックリスト
  Future<List<TrackRecord>> searchTracks({
    int limit = 50,
    DateTime? before,
    String? memoKeyword,
    List<String>? tagIds,
    int? condition,
  }) async {
    final query = _db.select(_db.tracks);

    // beforeフィルタ
    if (before != null) {
      query.where((t) => t.createdAt.isSmallerThanValue(before));
    }

    // memoキーワードフィルタ
    if (memoKeyword != null && memoKeyword.isNotEmpty) {
      query.where((t) => t.memo.like('%$memoKeyword%'));
    }

    // conditionフィルタ
    if (condition != null) {
      query.where((t) => t.condition.equals(condition));
    }

    // tagIdsフィルタ（JSON文字列を部分一致検索）
    if (tagIds != null && tagIds.isNotEmpty) {
      query.where((t) {
        // 各タグIDがJSON配列に含まれているかOR条件でチェック
        Expression<bool>? expr;
        for (final tagId in tagIds) {
          final condition = t.tagIds.like('%"$tagId"%');
          expr = expr == null ? condition : expr | condition;
        }
        return expr!;
      });
    }

    // 降順ソート、limit適用
    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);

    return await query.get();
  }

  /// トラックを新規作成
  ///
  /// パラメータ:
  /// - memo: メモ（最大1000文字、省略可）
  /// - condition: コンディション（-2〜2、デフォルト: 0）
  /// - tagIds: タグIDリスト
  ///
  /// 処理:
  /// - UUID v7を生成
  /// - createdAt, updatedAtに現在時刻を設定
  /// - 存在しないタグIDは除外して保存
  ///
  /// 例外:
  /// - ValidationException: バリデーションエラー
  Future<TrackRecord> createTrack({
    String? memo,
    int condition = 0,
    List<String> tagIds = const [],
  }) async {
    // バリデーション
    final memoError = validateTrackMemo(memo);
    if (memoError != null) {
      throw ValidationException(memoError, issues: {'memo': [memoError]});
    }

    final conditionError = validateCondition(condition);
    if (conditionError != null) {
      throw ValidationException(conditionError, issues: {'condition': [conditionError]});
    }

    // 存在するタグIDのみフィルタ
    final validTagIds = await _filterValidTagIds(tagIds);

    final now = DateTime.now().toUtc();
    final id = _uuid.v7();

    final companion = TracksCompanion.insert(
      id: id,
      memo: Value(memo),
      condition: Value(condition),
      tagIds: validTagIds,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.tracks).insert(companion);

    // 作成したレコードを返す
    return (await (_db.select(_db.tracks)..where((t) => t.id.equals(id))).getSingle());
  }

  /// トラックを更新
  ///
  /// パラメータ:
  /// - id: 更新対象のトラックID
  /// - memo: 新しいメモ（省略可）
  /// - condition: 新しいコンディション（省略可）
  /// - tagIds: 新しいタグIDリスト（省略可）
  ///
  /// 処理:
  /// - updatedAtを現在時刻に更新
  /// - 存在しないタグIDは除外して保存
  ///
  /// 例外:
  /// - NotFoundException: IDが存在しない
  /// - ValidationException: バリデーションエラー
  Future<TrackRecord> updateTrack({
    required String id,
    String? memo,
    int? condition,
    List<String>? tagIds,
  }) async {
    // 存在チェック
    final existing = await (_db.select(_db.tracks)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw NotFoundException('トラックが見つかりません: $id');
    }

    // バリデーション
    if (memo != null) {
      final memoError = validateTrackMemo(memo);
      if (memoError != null) {
        throw ValidationException(memoError, issues: {'memo': [memoError]});
      }
    }

    if (condition != null) {
      final conditionError = validateCondition(condition);
      if (conditionError != null) {
        throw ValidationException(conditionError, issues: {'condition': [conditionError]});
      }
    }

    // 存在するタグIDのみフィルタ
    final validTagIds = tagIds != null ? await _filterValidTagIds(tagIds) : null;

    // 更新内容を構築
    final companion = TracksCompanion(
      memo: memo != null ? Value(memo) : const Value.absent(),
      condition: condition != null ? Value(condition) : const Value.absent(),
      tagIds: validTagIds != null ? Value(validTagIds) : const Value.absent(),
      updatedAt: Value(DateTime.now().toUtc()),
    );

    await (_db.update(_db.tracks)..where((t) => t.id.equals(id))).write(companion);

    // 更新後のレコードを返す
    return (await (_db.select(_db.tracks)..where((t) => t.id.equals(id))).getSingle());
  }

  /// トラックを削除
  ///
  /// パラメータ:
  /// - id: 削除対象のトラックID
  ///
  /// 例外:
  /// - NotFoundException: IDが存在しない
  Future<void> deleteTrack(String id) async {
    final count = await (_db.delete(_db.tracks)..where((t) => t.id.equals(id))).go();
    if (count == 0) {
      throw NotFoundException('トラックが見つかりません: $id');
    }
  }

  /// 存在するタグIDのみフィルタリング
  ///
  /// 内部ヘルパー関数。存在しないタグIDを除外する。
  ///
  /// パラメータ:
  /// - tagIds: フィルタ対象のタグIDリスト
  ///
  /// 戻り値: 存在するタグIDのみのリスト
  Future<List<String>> _filterValidTagIds(List<String> tagIds) async {
    if (tagIds.isEmpty) {
      return [];
    }

    final validTags = await (_db.select(_db.tags)
      ..where((t) => t.id.isIn(tagIds))).get();

    return validTags.map((t) => t.id).toList();
  }
}
