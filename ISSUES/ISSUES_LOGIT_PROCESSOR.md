# イシュー: ロジットプロセッサによるサンプリング制御

## 概要
`lasada` のローカル推論エンジンは `LogitsProcessor` を用いて、推論中のロジットに対してサンプリング（Temperature, Top-P 等）を適用している。

## 詳細タスク
- [x] `src/Plugins/LogitsProcessor.lean`: `candle` が提供するロジットプロセッサの Lean ラッパーの実装。
- [x] サンプリングパラメータを動的に変更可能な状態管理ロジック。
