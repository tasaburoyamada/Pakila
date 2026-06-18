# イシュー: 非同期タスクのタイムアウト制御基盤

## 概要
`lasada` は `tokio::time::sleep` を用いたタイムアウト制御を行い、一定時間経過時に `AppError::Timeout` を発生させる。

## 詳細タスク
- [x] `src/Core/Async.lean`: `Task` または `IO` 処理に対して非同期タイムアウトを適用するラッパー関数。
- [x] `waitAny` 等を用いたタスクキャンセルロジックの実装。
