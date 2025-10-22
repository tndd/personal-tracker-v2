# ドキュメント構成

本プロジェクトのドキュメント一覧と参照ガイド。

---

## 📚 実装者向けドキュメント

### [requirements.md](requirements.md)
Flutter実装の要件定義書。

**内容:**
- 背景と目的
- プラットフォーム要件（Desktop / Android / Web）
- アーキテクチャ指針（Riverpod, Drift, GoRouter）
- 機能要件の概要
- テスト戦略
- 開発フェーズとリスク

**読むべきタイミング:** プロジェクト開始時、各Phase開始前

---

### [schema.md](schema.md)
データベーススキーマ定義（Drift + SQLite）。

**内容:**
- 全テーブル構造（Category, Tag, Track, Daily）
- 各フィールドの型、制約、説明
- 整合条件（sortOrderの連番、UNIQUE制約など）
- インデックス定義

**読むべきタイミング:** データ層実装時、テーブル構造の確認時

**関連ファイル:** `lib/shared/db/*.drift`

---

### [validation.md](validation.md)
バリデーションルール定義。

**内容:**
- 各フィールドの制約条件
- エラーメッセージ（日本語）
- 実装例（Dartコード）
- カラーパレット定義

**読むべきタイミング:** フォーム実装時、バリデーション実装時

**関連ファイル:** `lib/features/*/validation/*.dart`

---

### [repository_spec.md](repository_spec.md)
Repository層のインターフェース仕様。

**内容:**
- 各Repositoryのメソッド定義
- パラメータと戻り値の詳細
- 例外の種類
- 使用例

**読むべきタイミング:** Repository実装時、UseCase実装時

**関連ファイル:** `lib/features/*/data/*_repository.dart`

---

### [ui_behavior.md](ui_behavior.md)
UI挙動の設計意図。

**内容:**
- 各画面のコンセプト（「Slackのように」「Googleカレンダーのように」）
- レイアウト方針
- スクロール方向、ページネーション
- 実装方針とコード例

**読むべきタイミング:** UI実装時、ウィジェット設計時

**関連ファイル:** `lib/features/*/ui/*.dart`

---

## 🖼️ UIデザイン参考

### [ui_images/](ui_images/)
UIデザインのスクリーンショット。

**ファイル一覧:**
- `tags.png` - タグ管理画面（メイン）
- `tags-add.png` - カテゴリ追加ダイアログ（カラーパレット）
- `track.png` - トラック記録画面
- `daily.png` - 日記画面（カレンダービュー）
- `daily-list.png` - 日記画面（リストビュー）
- `analysis1.png` - 分析画面（コンディション推移）
- `analysis2.png` - 分析画面（集計）
- `analysis3.png` - 分析画面（タグ相関）

**使い方:**
- UIレイアウトの再現
- 色使い、ボタン配置の確認
- ユーザー体験の理解

---

## 🗂️ ディレクトリ構造

```
docs/
├── README.md              # 本ファイル
├── requirements.md        # 要件定義
├── schema.md              # DBスキーマ
├── validation.md          # バリデーション
├── repository_spec.md     # Repository仕様
├── ui_behavior.md         # UI設計意図
└── ui_images/             # スクリーンショット
    ├── tags.png
    ├── tags-add.png
    ├── track.png
    ├── daily.png
    ├── daily-list.png
    └── analysis*.png
```

---

## 📖 ドキュメントの読み方

### Phase 1（データ層実装）の場合
1. **requirements.md** - 全体像を把握
2. **schema.md** - テーブル定義を確認
3. **repository_spec.md** - Repository仕様を理解
4. 実装開始

### Phase 2（カテゴリ/タグUI実装）の場合
1. **requirements.md** - Phase2の要件を確認
2. **ui_behavior.md** - Tags画面のコンセプトを理解
3. **ui_images/tags.png, tags-add.png** - レイアウトを確認
4. **validation.md** - フォームのバリデーションを実装
5. 実装開始

### Phase 3（トラック実装）の場合
1. **ui_behavior.md** - Track画面のコンセプトを理解
2. **ui_images/track.png** - レイアウトを確認
3. **schema.md** - Track テーブルの仕様を確認
4. **repository_spec.md** - searchTracks のページング方式を理解
5. 実装開始

---

## 🔄 ドキュメント更新方針

### 更新が必要なケース
- 新しいテーブルやフィールドを追加した → `schema.md` を更新
- バリデーションルールを変更した → `validation.md` を更新
- Repository のメソッドを追加した → `repository_spec.md` を更新
- UI の挙動を変更した → `ui_behavior.md` を更新

### 更新不要なケース
- 実装の詳細（内部リファクタリング）
- コメントの修正
- テストコードの追加

---

## ❓ よくある質問

### Q: バリデーションのエラーメッセージはどこに定義されていますか？
A: `validation.md` に全て記載されています。日本語のエラーメッセージを統一するため、実装前に必ず確認してください。

### Q: カテゴリの色はどこから選べばいいですか？
A: `validation.md` のカラーパレット定義（8色）を使用してください。カスタム色は現時点では非対応です。

### Q: 並び替え（reorder）の仕様が分かりません。
A: `schema.md` の整合条件セクションと `repository_spec.md` の reorder メソッドを参照してください。sortOrder は必ず 0 からの連番である必要があります。

### Q: UI のレイアウトが元の画像と違います。
A: `ui_images/*.png` を参照して、ボタン配置や色使いを再現してください。不明な点は `ui_behavior.md` で設計意図を確認してください。

### Q: データベースの詳細仕様はどこにありますか？
A: `schema.md` に全てのテーブル定義が記載されています。Drift + SQLite によるローカルDBで実装しています。
