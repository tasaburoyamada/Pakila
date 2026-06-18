# イシュー: CLI インターフェースと設定管理の欠如

## 概要
`lasada` は CLI 引数解析 (clap)、環境変数管理 (dotenv)、設定ファイルロード (config) を備えているが、`pakila` にはこれらの機能が一切実装されていない。

## 詳細タスク
- [x] `src/CLI/Args.lean`: clap 相当の引数パーサーの実装。
- [x] `src/Config/Loader.lean`: `.toml` または `.yaml` 設定ファイルのロード機能。
- [x] `src/CLI/Session.lean`: セッション保存/ロードと、履歴のエクスポート機能。
