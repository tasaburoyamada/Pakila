# イシュー: 環境変数・設定ファイルの読み込み優先順位管理

## 概要
`lasada` は `.env` ファイル、`config.toml`、システム環境変数の優先順位（Env > Config > Default）で API キーや設定をロードしている。`pakila` ではこの優先順位に基づいたロードロジックが未実装。

## 詳細タスク
- [x] `src/Config/Loader.lean`: `dotenv` のような環境変数読み込みの実装。
- [x] `config.toml` を読み込み、環境変数で上書きする優先順位解決メカニズムの実装。
