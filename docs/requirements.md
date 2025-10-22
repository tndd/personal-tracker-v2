# personal-tracker-v2 要件定義書

## 1. 背景
- 既存の `personal_tracker`（Next.js + Drizzle + PostgreSQL）は Web 専用であり、SSR/API Routes/外部 DB に強く依存している。
- ユーザー要件として「外部サーバーには依存せず、各端末にデータを保存できること」が追加された。
- また、将来的な Desktop / Mobile（Android・iOS 任意）/ Web サポートを一つのコードベースで維持したい。

## 2. 目的
1. 既存仕様書（`docs/specification/*.md`）で定義されているドメインモデル・振る舞いをローカルファーストで再実装する。
2. Flutter を用いて Desktop / Android / Web（+ iOS 任意）の複数プラットフォームに対応する UI を提供する。
3. 端末内の SQLite を主ストレージとし、バックアップとリストアのフローを整備する。

## 3. 用語
- **カテゴリ (category)**: 記録を分類する上位概念。色付きで表示。
- **タグ (tag)**: カテゴリに属する細分化されたラベル。トラックに紐付けられる。
- **トラック (track)**: 時系列の出来事ログ。メモ・コンディション（-2〜2）・複数タグを持つ。
- **日記 (daily)**: 1 日 1 件の詳細な記録。メモ・睡眠・コンディションを保持。
- **分析 (analysis)**: トラック／日記データを集計し、統計や傾向を表示する機能群。

## 4. 対象プラットフォーム
- **必須**: Web（ブラウザ版）、macOS / Windows / Linux デスクトップ、Android
- **任意（将来対応）**: iOS
- 各プラットフォームで共通のソースコードを維持し、UI レイアウトは各デバイスサイズに応じて調整する。

## 5. データ永続化要件
- SQLite（Drift）を正とする。Web では sqlite3_wasm + IndexedDB/OPFS を利用し、モバイル/デスクトップはネイティブ SQLite を使用する。
- 各テーブルのスキーマは旧実装と同等に定義する。

### 5.1 テーブル仕様（Drift 定義方針）

#### category
| カラム | 型 | 制約 |
| --- | --- | --- |
| id | TEXT(UUID) | 主キー、`uuidv7` を採用 |
| name | TEXT | NOT NULL、一意 |
| color | TEXT | NOT NULL、`^#[0-9A-Fa-f]{6}$` バリデーション |
| sort_order | INTEGER | NOT NULL、全体で連番維持 |
| archived_at | TIMESTAMP | NULLABLE（JST 表示時はローカル変換） |
| created_at / updated_at | TIMESTAMP | NOT NULL、更新時にアプリ側で再設定 |

#### tag
| カラム | 型 | 制約 |
| --- | --- | --- |
| id | TEXT(UUID) | 主キー |
| category_id | TEXT(UUID) | NOT NULL、`ON DELETE CASCADE` |
| name | TEXT | NOT NULL、カテゴリ内で一意 |
| sort_order | INTEGER | NOT NULL、カテゴリ内で連番 |
| archived_at | TIMESTAMP | NULLABLE |
| created_at / updated_at | TIMESTAMP | NOT NULL |

#### track
| カラム | 型 | 制約 |
| --- | --- | --- |
| id | TEXT(UUID) | 主キー |
| memo | TEXT | NULLABLE、最大 1000 文字 |
| condition | INTEGER | -2〜2、デフォルト 0 |
| tag_ids | TEXT(JSON) | UUID 配列を JSON で保存（Drift では `List<String>`） |
| created_at / updated_at | TIMESTAMP | NOT NULL |

- `tag_ids` に不明な ID があっても保存時に除外する処理を入れる。

#### daily
| カラム | 型 | 制約 |
| --- | --- | --- |
| date | TEXT(YYYY-MM-DD) | 主キー |
| memo | TEXT | NULLABLE、最大 5000 文字 |
| condition | INTEGER | -2〜2、デフォルト 0 |
| sleep_start / sleep_end | TIMESTAMP | NULLABLE |
| created_at / updated_at | TIMESTAMP | NOT NULL |

### 5.2 タイムゾーン方針
- DB は UTC 保管、表示・集計は JST 基準。
- 既存 `src/lib/timezone.ts` のロジックを Dart で再実装し、JST の日付境界を揃える。

### 5.3 バックアップ / エクスポート
- JSON（すべてのテーブルを含む）エクスポートと、逆に JSON からのインポートを UI に提供。
- 手動エクスポートでクラウドストレージへ保存できるよう OS 標準のファイルピッカーを利用。
- 自動バックアップは将来検討。短期的にはユーザー通知と確認ダイアログを設ける。

## 6. 機能要件

### 6.1 共通
- 起動時に SQLite を初期化し、必要なマイグレーションを即時適用する。
- 全データ操作はリポジトリ層を経由し、状態管理（Riverpod）へストリーム配信する。
- UI からの入力バリデーションは Zod 相当の Dart 実装（`formz` もしくは独自ロジック）で実装し、旧 API のエラーメッセージ仕様（日本語）を踏襲する。

### 6.2 カテゴリ管理
- 一覧表示（アーカイブ有無のフィルタ付き）。
- 追加（`sort_order` 自動採番）。
- 編集（名称・色・アーカイブ状態）。
- 並び替え（ドラッグ & ドロップ、連番制約を再現）。

### 6.3 タグ管理
- カテゴリごとの一覧、アーカイブ切替。
- 作成・編集・並び替えは API 仕様と同様。
- カテゴリ削除時に紐づくタグは連鎖削除。

### 6.4 トラック
- 無限スクロール（降順）。
- メモ / コンディション / タグの CRUD。
- タグ選択時はカテゴリ別の色付きチップを表示。
- 検索（文字列 & タグ & コンディション）フィルター。
- レコード削除。

### 6.5 日記
- カレンダー / リスト表示切替。
- 任意日付での記入（1 日 1 件）・編集。
- コンディション・睡眠時間の入力補助（時刻ピッカー）。
- コンディションフィルター。

### 6.6 分析
- `condition-trend`: 期間指定（デフォルト30日）で日記条件の折れ線グラフ。
- `condition-daily`: 日次集計（平均/最小/最大/件数/睡眠時間）。
- `condition-track`: トラックの条件分布を週次 / 月次で可視化。
- `tag-correlation`: ベイズ推定によるタグ寄与度を算出。重み付き平均・信用区間を旧ロジックに合わせて実装。
- グラフ描画は `fl_chart` などのチャートライブラリを利用。

### 6.7 設定
- バックアップ／リストア UI。
- テーマ切替（ライト/ダーク）。
- ログ出力（デバッグ用途）。

## 7. 非機能要件
- **パフォーマンス**: 1 万件のトラックでもスクロールが滑らかであること。リストは仮想化（`ListView.builder`）を徹底。
- **オフライン**: ネット接続不要。外部 API 呼び出しは存在しない。
- **セキュリティ**: 端末ローカル保存だが、オプションでデータ暗号化の拡張ポイントを設ける。
- **可観測性**: ログは `logger` パッケージで統一し、開発ビルドでは devtools へ出力。

## 8. アーキテクチャ指針
- **レイヤー構成**: `presentation`（Widget + ViewModel） / `application`（UseCase） / `domain`（モデル） / `infrastructure`（DB, Platform）。
- **状態管理**: Riverpod + StateNotifier。監視フロー（StreamProvider）で DB の変更を購読。
- **DB アクセス**: Drift の DAO / Queries を use case から呼び出す。マイグレーションは `Migrator` で version 管理。
- **日付処理**: `intl` と `timezone` パッケージで JST 基準を実現。
- **DI**: Riverpod Provider で共通依存を注入。
- **ルーティング**: GoRouter で画面遷移を定義。Web / モバイル共通 URL 設計。

## 9. データ移行
- Next.js 版からの移行は任意。JSON エクスポート（旧 API）→ Flutter 側インポートのコマンドラインツールを用意する。
- Postgres → SQLite 変換スクリプトは Dart CLI として実装（スキーマ互換を担保）。

## 10. テスト戦略
- **ユニットテスト**: UseCase / Repository / Converter。
- **ウィジェットテスト**: トラック一覧、日記フォーム、グラフ描画。
- **Integration Test**: 主要ユーザーフロー（トラック作成→タグ付与→分析表示）。
- **Golden Test**: 代表画面のレイアウトをゴールデン化し、プラットフォーム差異を検出。

## 11. 開発プロセス（推奨フェーズ）
1. **フェーズ 0**: Flutter プロジェクト初期化、Drift/Freezed セットアップ。
2. **フェーズ 1**: データ層（スキーマ・マイグレーション）の実装とテスト。
3. **フェーズ 2**: カテゴリ／タグ UI + 状態管理。
4. **フェーズ 3**: トラック UI・インフィニットスクロール・フィルター。
5. **フェーズ 4**: 日記 UI（カレンダー含む）。
6. **フェーズ 5**: 分析（集計ロジック + グラフ）。
7. **フェーズ 6**: バックアップ/リストア + 設定画面。
8. **フェーズ 7**: E2E / Integration テスト、アプリ配布準備。

## 12. リスクとオープン課題
- `tag-correlation` のベイズ推定ロジックを Flutter へ移植する際、旧実装（Next.js API）のアルゴリズム詳細が要確認。必要に応じて Rust/Dart で数値安定化を図る。
- Web 版の sqlite3_wasm はブラウザ互換性を十分に検証する必要がある（Safari 対応 ECMAScript Module の扱い）。
- iOS 対応を行う場合、バックアップのファイル保存先や App Sandbox 設定を追加で設計する。

## 13. 参照
- 既存仕様: `../personal_tracker/docs/specification/`
- 既存実装: `../personal_tracker/src/app/api/*`, `../personal_tracker/src/components/*`
- Tauri / Next.js 版 PoC: `../personal_tracker/docs/issue/001_tauri-cross-platform-poc.md`
