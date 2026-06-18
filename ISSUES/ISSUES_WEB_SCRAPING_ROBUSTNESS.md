# イシュー: Web クライアントの耐性とクッキー管理

## 概要
`lasada` の `WebExecutor` は、User-Agent 設定やリトライ制御を行っているが、`pakila` では単純なクエリ実行のみが計画されている。

## 詳細タスク
- [x] `src/Plugins/WebHeaderManager.lean`: User-Agent や Cookie 等の HTTP ヘッダーをセッション間で保持・管理する基盤。
- [x] `src/Plugins/WebRetry.lean`: Web ページ取得がブロックされた際のリトライ戦略およびエラー分類。
- [x] `src/Plugins/HtmlParser.lean`: 不要なタグや広告を排除した、軽量かつ高精度なテキスト抽出アルゴリズムの実装。
