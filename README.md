# personal-tracker-v2

Flutter を用いて再構築するローカルファースト型の健康管理アプリです。既存の Next.js + PostgreSQL 実装で提供されている「カテゴリ／タグ管理」「トラック記録」「日記」「統計分析」の機能を、単一コードベースで Desktop / Android / iOS（任意） / Web へ展開できるようにすることを目的としています。

## 背景と狙い
- 現行 Web 版は SSR と API Routes、外部 PostgreSQL への永続化を前提としており、オフライン環境では利用できません。
- 本リポジトリではローカル DB を前提とした Flutter アプリを新規実装し、既存仕様を踏襲しつつマルチプラットフォーム対応を実現します。
- 必須要件はデバイス内完結のデータ保持と、既存仕様（`docs/specification/*.md`）で定義されている振る舞いの再現です。

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
- `docs/requirements.md`: 実装要件定義書。本 README と併せて参照してください。
- `docs/architecture/`（今後追加予定）: 実装詳細・設計補足

## メモ
- 既存 Next.js 実装の API/DB 仕様は `../personal_tracker/docs/specification/` にまとまっています。Flutter 実装ではこれらのバリデーションルールやデータ構造を Drift スキーマとドメイン層で再現します。
- データは端末内 SQLite へ保存し、エクスポート/インポート機能でバックアップを提供します（詳細は requirements.md を参照）。
