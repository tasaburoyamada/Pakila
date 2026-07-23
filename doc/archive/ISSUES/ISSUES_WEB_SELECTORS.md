# イシュー: Web スクレイピング用 CSS セレクタの最適化

## 概要
`lasada` の `WebExecutor` は DuckDuckGo の特定の CSS セレクタ (`.result__body`, `.result__a`, `.result__snippet`) を用いて情報を抽出している。`pakila` でこれを実装する際、構造変更に対応するためのセレクタ管理が必要。

## 詳細タスク
- [x] `src/Plugins/HtmlParser.lean`: 検索サイトの HTML 構造変更に柔軟に対応するための、セレクタ設定管理ロジックの実装。
- [x] 抽出失敗時（結果が 50 文字未満など）の警告および代替抽出ロジックへのフォールバック。
