# イシュー: 実行ディスパッチャーの動的レジストリ実装

## 概要
`lasada` の `ExecutionDispatcher` は `HashMap` を利用してExecutorを登録・管理しているが、`pakila` では動的なレジストリとデフォルトのフォールバックロジックが未実装。

## 詳細タスク
- [x] `src/Plugins/Dispatcher.lean`: ツール名をキーとして `ExecutionEngine` を登録・検索するレジストリ構造の実装。
- [x] 未定義の言語が指定された場合の BashExecutor への動的フォールバック実装。
- [x] 非同期実行時の Executor 間でのセッション同期機能（概念的）。
