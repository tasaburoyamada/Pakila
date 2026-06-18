# イシュー: LLM バックエンドの認証・フォーマット自動発見とキャッシュ

## 概要
`lasada` の `OpenAICompatibleLlm` は、ヘッダー形式 (`Authorization: Bearer` vs `api-key`) およびリクエストボディ形式 (`include_usage` の有無) を動的に探索し、成功した組み合わせをキャッシュする機能を備えている。

## 詳細タスク
- [x] `src/Plugins/LlmClient.lean`: 複数の認証・ボディパターンの定義と探索ループの実装。
- [x] 成功した `(pattern_index, auth_index)` のメモリ内キャッシュおよび再利用ロジック。
- [x] 初回成功時のデバッグログ出力（マスクされたAPIキー情報の表示）。
