# イシュー: LLM ストリーミング通信と自動形式発見の実装

## 概要
`lasada` の `OpenAICompatibleLlm` は、複数の認証パターン（Authorization/api-key）とリクエスト形式（include_usage オプションの有無）を試行錯誤し、成功するまで自動探索する機能を持つ。また、SSE形式のストリームから JSON チャンクを正規表現で抽出し、動的に解析している。`pakila` では未実装。

## 詳細タスク
- [x] `src/Plugins/LlmClient.lean`: API キー認証パターン（Authorizationヘッダー vs api-keyヘッダー）の動的探索および成功した形式のキャッシュ保存メカニズム。
- [x] `src/Plugins/StreamParser.lean`: SSE (`data: ...`) 形式のバイトストリームから JSON チャンクを抽出し、再帰的に構造化するパーサーの実装。
- [x] マルチモーダル対応（`image_url`）のためのメッセージ構造の拡張と型安全な変換。
