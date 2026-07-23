# イシュー: 複雑なExecutorプラグインの未実装

## 概要
`lasada` には `PythonExecutor`、`WebExecutor`、`ComputerExecutor` という高度な機能が含まれているが、`pakila` は `Bash` のみ。

## 詳細タスク
- [x] `src/Plugins/Python.lean`: 安全なPython実行セッションの実装。
- [x] `src/Plugins/Web.lean`: インターネット検索/スクレイピングの機能統合。
- [x] `src/Plugins/Computer.lean`: OSの入力・GUI操作を模倣するエージェント機能の実装。
