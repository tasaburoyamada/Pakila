# イシュー: リソースクリーンアップとプロセス終了時の整合性

## 概要
`lasada` の各 Executor（Computer, Python 等）は生成された一時ファイルや子プロセスを終了時にクリーンアップするロジックを持つ。`pakila` ではプロセス終了時のリソース解放責任が不明確。

## 詳細タスク
- [x] `src/Plugins/ResourceTracker.lean`: `ExecutionEngine` ライフサイクルに紐づいた一時ファイル (`/tmp/lasada_*.jpg`) および子プロセスの追跡と終了時自動削除機能。
- [x] SIGINT/SIGTERM 受信時のアトミックなリソース解放プロトコル。
