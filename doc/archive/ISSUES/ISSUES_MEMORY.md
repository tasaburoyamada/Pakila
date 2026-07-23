# イシュー: 長期記憶 (RAG) とトークン管理の不足

## 概要
`lasada` は `VectorDB` を用いた長期記憶検索 (RAG) と `tiktoken` を用いたトークン管理機能を備えている。`pakila` はこれらが未実装であり、コンテキスト管理能力が低い。

## 詳細タスク
- [x] `src/Memory/VectorDB.lean`: ベクトルデータベースの実装と検索機能。
- [x] `src/Memory/TokenManager.lean`: コンテキスト制限を管理するためのトークン数計算ロジック。
- [x] `src/Memory/Summarizer.lean`: 履歴が長くなった際の自動要約機能。
