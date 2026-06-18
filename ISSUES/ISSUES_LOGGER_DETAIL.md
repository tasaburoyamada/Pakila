# イシュー: ログフォーマットと出力詳細の精密化

## 概要
`lasada` は `fern` を使用し、`chrono` でタイムスタンプを生成し、色付け（`colored`）を適用したフォーマットでログ出力を行っている。

## 詳細タスク
- [x] `src/Observability/LogPipeline.lean`: `chrono` 相当の時間フォーマット (YYYY-MM-DD HH:MM:SS) を実装。
- [x] コンソール出力時の ANSI カラー制御シーケンスの共通化と、ログレベルに応じた動的な色分けロジックの実装。
