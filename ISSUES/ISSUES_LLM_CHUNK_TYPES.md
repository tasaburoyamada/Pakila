# イシュー: LLM ストリーミングチャンクの型定義詳細

## 概要
`lasada` の `LlmResponseChunk` には `Text` (文字列) と `ToolCall` (関数呼び出し) の区別が存在し、ストリームからこれらを分離して抽出するロジックが必要である。`pakila` では `Text` しか扱っていない。

## 詳細タスク
- [x] `src/Core/Types.lean`: `LlmResponseChunk` の Inductive 型定義（`Text`, `ToolCall` 等の網羅）。
- [x] ストリームパーサーにおいて、JSON チャンク内の `delta.tool_calls` を検出し、`ToolCall` 型へ変換するデシリアライズロジックの実装。
