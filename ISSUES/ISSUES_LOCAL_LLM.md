# イシュー: ローカル LLM 推論エンジンの未実装

## 概要
`lasada` は `candle-core` を用いて、量子化された Llama モデル（GGUF）をホスト内で直接実行する機能を備えている。`pakila` では、これと同等の低レベルなテンソル操作および量子化モデルのロード機能が未実装である。

## 詳細タスク
- [x] `src/Plugins/LocalCandle.lean`: `candle-core` のような低レベルテンソル演算ライブラリを Lean でラップし、GGUF モデルをロードして推論するエンジンの実装。
- [x] `src/Plugins/Tokenizer.lean`: `tokenizers` ライブラリの Lean 移植およびトークン化ロジックの再実装。
- [x] 量子化パラメータの型安全な管理と、計算時のメモリリーク防止メカニズムの構築。
