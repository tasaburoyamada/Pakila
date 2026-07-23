# イシュー: 推論サンプリングパラメータの動的制御

## 概要
`lasada` の `OpenAICompatibleLlm` は、リクエストオプションとして `temperature` や `top_p` を動的に受け取り、モデルの推論挙動を制御している。`pakila` ではこれらが未実装。

## 詳細タスク
- [x] `src/Core/Traits.lean`: `LlmRequestOptions` 構造体の定義と、モデルへのパラメータ渡し機能。
- [x] 各バックエンド実装におけるパラメータ適用ロジックの実装。
