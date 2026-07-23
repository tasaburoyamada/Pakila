# イシュー: コア機能の実装不備と完全性

## 概要
`pakila` のコア型定義およびトレイトの実装は最小限のスケルトンであり、`lasada` が提供する Rust 実装の完全な機能を網羅していない。

## 詳細タスク
- [x] `AppError` の網羅性確認: `lasada` の全ての例外ケース（`LlmError`, `ExecutionError`, `ConfigError`, `Timeout` 等）が Lean 4 の Inductive 型において論理的に尽くされているか検証。
- [x] `Message` 構造体の型安全性向上: 現在の `String` ベースの定義から、より構造化された型への移行。
- [x] `LlmBackend` および `ExecutionEngine` トレイトの非同期動作の Lean モナドへの完全マッピング（`IO` 型クラスにおける安全性保証）。
