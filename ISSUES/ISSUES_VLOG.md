# イシュー: .vlog パーサーの機能不足

## 概要
`VlogParser` は現状スタブであり、`lasada` で定義されている HV-CAD の制御機能（`@BIAS` 等によるステート操作）が実現できていない。

## 詳細タスク
- [x] `VlogParser`: `Lean.Parsec` を用いた、正式な構文定義に基づくパーサー実装。
- [x] `Message` への `@BIAS` 注入ロジックの具体化。
- [x] `vlog` ファイルの文法と Lean のデータ構造間の双方向変換の検証。
