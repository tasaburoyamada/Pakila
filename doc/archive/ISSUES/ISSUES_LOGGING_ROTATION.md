# イシュー: ログ出力のローテーションと詳細制御

## 概要
`lasada` は `fern` ライブラリを使用してログ出力を制御している。`pakila` では単純な出力しかないため、運用に必要なログの永続化とレベル指定が不足。

## 詳細タスク
- [x] `src/Observability/LogPipeline.lean`: 実行毎にファイル（`YYYY-MM-DD-HH-MM.log` 形式）を分けるログローテーション処理。
- [x] CLI オプション (`--debug`) に連動したログレベル（Debug/Info）の動的切り替え機能。
