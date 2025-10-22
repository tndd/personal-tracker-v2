# personal-tracker-v2

Flutter で構築するローカルファースト型の健康管理アプリです。「カテゴリ／タグ管理」「トラック記録」「日記」「統計分析」の機能を提供し、単一コードベースで Desktop / Android / iOS（任意） / Web へ展開します。

## 特徴
- **オフライン完結**: 外部サーバーに依存せず、デバイス内で完結するデータ保持
- **マルチプラットフォーム**: Desktop（macOS / Windows / Linux）、Android、Web、iOS（任意）
- **ローカルDB**: SQLite によるデータ永続化
- **バックアップ/リストア**: JSON エクスポート/インポート機能

## 技術スタック（想定）
- **言語 / SDK**: Flutter 3.24 以降, Dart 3.5 以降
- **状態管理**: Riverpod（`flutter_riverpod`）
- **データ永続化**: Drift + sqlite3_flutter_libs（モバイル／デスクトップ）, sqlite3_wasm（Web）
- **データクラス生成**: Freezed + json_serializable
- **DI / ルーティング**: Riverpod + GoRouter
- **デザインシステム**: Material 3 + 自前テーマ（既存 Tailwind デザイン指針を参考）
- **テスト**: `flutter_test`（ユニット・ウィジェット）/ `integration_test`（主要フロー）

## 想定ディレクトリ構成

```
personal-tracker-v2/
├─ lib/
│  ├─ app/              # ルーティング、全体設定
│  ├─ features/
│  │   ├─ category/
│  │   ├─ tag/
│  │   ├─ track/
│  │   ├─ daily/
│  │   └─ analysis/
│  ├─ shared/
│  │   ├─ db/           # Drift 定義・マイグレーション
│  │   ├─ models/
│  │   ├─ services/
│  │   └─ widgets/
│  └─ utils/
├─ assets/
├─ test/
├─ integration_test/
└─ docs/
```

## 開発環境セットアップ

1. Flutter SDK を 3.24 以降へアップデートし、必要なターゲットのサポートを有効化します。
   ```bash
   flutter upgrade
   flutter config --enable-macos-desktop --enable-windows-desktop --enable-linux-desktop
   flutter config --enable-web
   ```
2. 依存関係を取得します。
   ```bash
   flutter pub get
   ```
3. Drift の生成コードを更新します。
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

## 実行方法

- Web (開発用): `flutter run -d chrome`
- macOS デスクトップ: `flutter run -d macos`
- Windows デスクトップ: `flutter run -d windows`
- Linux デスクトップ: `flutter run -d linux`
- Android 実機 / エミュレータ: `flutter run -d <android-device-id>`
- iOS（任意対応）: `flutter run -d <ios-device-id>` ※署名・プロビジョニング設定が別途必要

## テスト

```bash
flutter test                    # ユニット・ウィジェットテスト
flutter test integration_test   # 主要 E2E フロー（Playwright 代替）
```

## ドキュメント

本プロジェクトのドキュメントは `docs/` ディレクトリに配置されています。

### 主要ドキュメント
- **[docs/requirements.md](docs/requirements.md)** - 実装要件定義書
- **[docs/schema.md](docs/schema.md)** - データベーススキーマ定義
- **[docs/validation.md](docs/validation.md)** - バリデーションルール
- **[docs/repository_spec.md](docs/repository_spec.md)** - Repository仕様
- **[docs/ui_behavior.md](docs/ui_behavior.md)** - UI挙動の設計意図

### UIデザイン参考
- **[docs/ui_images/](docs/ui_images/)** - UIデザインのスクリーンショット

詳細は **[docs/README.md](docs/README.md)** を参照してください。
