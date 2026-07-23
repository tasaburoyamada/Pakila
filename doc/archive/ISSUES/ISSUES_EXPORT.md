# イシュー: セッション履歴のエクスポート機能

## 概要
`lasada` には、インタラクティブ・セッションの履歴を Markdown 形式で保存する機能がある。現在の `pakila` にはこの機能がない。

## 詳細タスク
- [x] `src/CLI/Exporter.lean`: 履歴 (`List Message`) を Markdown ファイル (`sessions/report_...md`) に整形・出力する関数の実装。
- [x] エクスポート時のファイル生成ロジックおよびディレクトリ自動作成機能。
