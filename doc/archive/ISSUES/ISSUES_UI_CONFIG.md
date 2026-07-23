# Priority: Class S

# イシュー: UI テーマおよび配色設定の未実装

## 概要
`lasada` は `config.toml` 内で UI の配色設定（color_user, color_ai 等）を保持しているが、`pakila` ではコンソール出力の配色管理機能が未実装。

## 詳細タスク
- [x] `src/CLI/Theme.lean`: `config.toml` の `[ui]` セクションを読み込み、コンソール出力を配色するための型定義とインターフェース。
- [x] 配色情報を利用した出力文字列の ANSI エスケープシーケンス生成関数。
