/// アプリケーションデータベース
///
/// Driftを使用したSQLiteデータベース接続とマイグレーション管理。
///
/// 使用例:
/// ```dart
/// final db = AppDatabase();
/// final categories = await db.select(db.categories).get();
/// await db.close(); // アプリ終了時
/// ```
///
/// 注意点:
/// - シングルトンではない（必要に応じてDIで管理）
/// - マイグレーションは初回起動時に自動実行
/// - インデックスはcreate時に設定
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import 'converter/json_converter.dart';

part 'database.g.dart';

/// アプリケーションデータベースクラス
///
/// 4つのテーブル（Categories, Tags, Tracks, Dailies）を管理し、
/// マイグレーションとインデックス作成を自動実行する。
@DriftDatabase(tables: [Categories, Tags, Tracks, Dailies])
class AppDatabase extends _$AppDatabase {
  /// デフォルトコンストラクタ（本番用）
  ///
  /// アプリケーションディレクトリにSQLiteファイルを作成する。
  AppDatabase() : super(_openConnection());

  /// テスト用コンストラクタ
  ///
  /// インメモリデータベースを使用する。
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // 全テーブルを作成
        await m.createAll();

        // インデックスを作成
        await customStatement(
          'CREATE INDEX IF NOT EXISTS category_sort_order_idx ON categories(sort_order);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS tag_category_id_idx ON tags(category_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS track_created_at_idx ON tracks(created_at);',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 将来のバージョンアップ時にマイグレーションを追加
      },
    );
  }
}

/// データベース接続を開く
///
/// アプリケーションのドキュメントディレクトリに `app.db` を作成する。
/// 戻り値: NativeDatabase インスタンス
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file);
  });
}
