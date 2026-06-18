# イシュー: 拡張プラグインの欠如

## 概要
`lasada` には `PythonExecutor`、`WebExecutor`、`ComputerExecutor` があるが、`pakila` は `Bash` のみしか実装されていない。

## 詳細タスク
- [x] `src/Plugins/Python.lean`: Python 実行環境の対話セッション実装。
- [x] `src/Plugins/Web.lean`: Web 検索およびスクレイピング機能の実装。
- [x] `src/Plugins/Computer.lean`: コンピュータ操作（GUI自動化）の実装。
- [x] `src/Plugins/Dispatcher.lean`: 複数のツールを管理・動的選択する ExecutionDispatcher の実装。
