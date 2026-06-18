# イシュー: SRP 準拠の 5 セクション動的構築

## 概要
`Gemini CLI` 仕様 (SRP) に基づき、全ての AI 応答は `[Topic Model]`, `[Strategic Intent]`, `Body`, `[Summary]`, `[Status]` を持たなければならない。`pakila` の出力パイプラインでこれを自動化する。

## 詳細タスク
- [x] `src/CLI/Protocol.lean`: 現在のアクティブなモデル情報を `LlmManager` から取得し `[Topic Model]` を生成する機能。
- [x] `strategicIntent` を状態として保持し、ターンの開始時に注入する機能。
- [x] ターン終了時に履歴の差分から `[Summary]` を自動生成、または LLM に生成させるロジックの統合。
- [x] `[Status]` 行の固定フォーマット出力の強制。
