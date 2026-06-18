# イシュー: ログ管理およびトレーサビリティの不足

## 概要
`lasada` は `fern` ライブラリを用いて時間ごとのログファイル生成およびレベル別（Debug/Info）ログ出力を行っている。`pakila` には同様のロギング・パイプラインが欠如している。

## 詳細タスク
- [x] `src/Observability/LogPipeline.lean`: 時間ベースのログファイル生成（`YYYYMMDDHHMM.log` 形式）およびログレベル（Debug/Info）制御の移植。
- [x] `src/Observability/Formatter.lean`: タイムスタンプ付与等のログフォーマット処理。
