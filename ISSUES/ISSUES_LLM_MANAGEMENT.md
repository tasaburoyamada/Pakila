# イシュー: LLM バックエンド管理・ルーティングロジックの未実装

## 概要
`lasada` の `LlmManager` は複数の LLM バックエンド（GoogleNative, LocalDirect, RemoteServer）を動的に切り替え、リクエストをルーティングする機能を持つが、`pakila` では完全に未実装。

## 詳細タスク
- [x] `src/Core/LlmManager.lean`: 複数のバックエンドを保持し、現在の `ActiveBackend` を切り替えるステートマシン的な管理ロジックの実装。
- [x] `LlmBackend` のトレイト実装クラスのファクトリ定義および管理。
- [x] バックエンド切り替え時のエラーハンドリングと再初期化プロトコル。
