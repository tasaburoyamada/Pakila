# イシュー: プロンプト管理とコンテキスト注入

## 概要
`lasada` の `Interpreter::init` では、シンボリックなステート (`@CTX`, `@BIAS`, `CONCEPT`) の注入やシステム情報収集が自動で行われている。`pakila` ではプロンプトエンジニアリング機能が不十分である。

## 詳細タスク
- [x] `src/Core/PromptManager.lean`: システム情報を収集し（OS, CPU, Mem等）、プロンプトへの自動注入ロジックの実装。
- [x] `src/Core/Context.lean`: コンテキスト制限の管理とメッセージ要約アルゴリズムの実装。
- [x] プロンプト注入における `.vlog` 状態の動的読み込みと適用。
- [x] `src/Memory/RAG.lean`: LLM インターフェースへの VectorDB 検索結果の RAG コンテキスト注入ロジック。
