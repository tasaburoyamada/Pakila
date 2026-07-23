# イシュー: Gemini CLI プロトコル (SRP) との適合性向上

## 概要
`Gemini CLI` 仕様 (SRP) で定義されている 5 つの必須セクション（Topic Model, Strategic Intent, Body, Summary, Status）の動的生成が `pakila` の CLI/LLM 統合部分に実装されていない。

## 詳細タスク
- [x] `src/CLI/Protocol.lean`: 全ての応答に対して SRP フォーマットを自動適用するラッパー関数の実装。
- [x] ターン末尾の `[Status]` 管理機能の追加。
- [x] ターンの自律検証結果を `[Summary]` に自動集約するロジックの実装。
