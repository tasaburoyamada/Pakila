# イシュー: 実行ディスパッチャーの機能欠如

## 概要
`lasada` には `ExecutionDispatcher` が存在し、複数のツールやexecutorを管理しているが、`pakila` ではツール選択や管理の仕組みが未定義。

## 詳細タスク
- [x] `src/Plugins/Dispatcher.lean`: `ToolDefinition` のレジストリ機能と、入力に応じた `ExecutionEngine` の動的選択メカニズム。
- [x] ツール利用可能性の形式的な型定義（どの executor がどのツールを実装しているか）。
