# ADR-004: Gemini 2.0 ネイティブ構造化出力および思考統合

## ステータス
承認済 (Accepted)

## コンテキスト
LLM のレスポンスをパースする際のアナライザエラーやフォーマット破壊を排除し、かつ思考プロセス (Thinking Part) とツール並列ディスパッチをネイティブにサポートする必要がある。

## 決定
- `Lyceum.Protocol.Types.structuredLlmResponseSchema` による OpenAPI スキーマを導入し、API レベルでレスポンス型をネイティブ拘束する。
- `thinking_config` (`thinkingBudget`, `includeThoughts`) および `GeminiPart.thought` に対応し、`Pakila.Actions.dispatchBatch` モナドによる並列ディスパッチを採用する。

## 帰結
- テキストパースによる実行時失敗を物理排除。
- 1 ターンにおける複数アクションの一括並列実行が安全に実現される。
