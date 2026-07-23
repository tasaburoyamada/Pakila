# Pakila システムアーキテクチャ設計書 (System Architecture Specification)

## 1. システム概要 (Executive Summary)

`Pakila` は、形式検証済みエージェント基盤における最上位オーケストレータおよびインタラクティブ実行環境である。Wasmtime サンドボックス、マルチモーダル入力、並びに `Lyceum` / `nomos` / `LeanTensor` / `lbir` を統合し、型安全かつ防腐性の高い統合 LLM ワークスペースを提供する。

---

## 2. C4 モデル アーキテクチャ図 (C4 Architecture Model)

### 2.1. Level 1: System Context (システムコンテキスト)
```
+-----------------------------------------------------------------+
|                        Pakila Application                       |
|               (Interactive UI / Execution Engine)               |
+-----------------------------------------------------------------+
          |                                       |
          v (MCP & Generic LLM)                   v (Formal Governance)
+-----------------------------------+   +----------------------------------+
|           Lyceum Core             |   |              nomos               |
| (Local & Remote LLM Backend)      |   | (State Verification & Law)       |
+-----------------------------------+   +----------------------------------+
          |
          v (Tensor Kernel)
+-----------------------------------+
|            LeanTensor             |
| (AVX-512 & Dependent Type Kernel) |
+-----------------------------------+
```

### 2.2. Level 2: Container Diagram (コンテナ構成)
- **`Pakila.Core.Machine`**: ステートマシン型メインループ。ユーザープロンプトとレスポンスを管理。
- **`Pakila.Core.Interface`**: Stdio / Physical Terminal 操作を抽象化する `TerminalEnv` 型クラス。
- **`Pakila.Plugin`**: Wasmtime C FFI 連携による動的プラットフォーム拡張。
- **`Pakila.Memory`**: VectorDB と物理埋め込みによる RAG コンテクスト検索エンジン。

### 2.3. Level 3: Component Diagram (コンポーネント構成)
- **`Pakila.Tokenizer`**: Unigram / WordPiece 日本語マルチバイトトークナイザ。
- **`Pakila.Sandbox`**: Wasm 外部コード安全実行サンドボックス。
- **`Pakila.MainLoop`**: `nomos` の `Agent` 契約に従う決定論的状態遷移ループ。

---

## 3. 構造化意思決定記録 (ADR: Architectural Decision Records)

### ADR-001: Wasmtime FFI サンドボックス分離
- **ステータス**: 承認済 (Accepted)
- **文脈**: プラグインやサードパーティツールの実行時にメインプロセスのメモリ破壊や OS 破壊を防ぐ必要がある。
- **決定**: `-lwasmtime` FFI を介した隔離サンドボックス環境を構築し、外部コマンド・コードを安全にカプセル化する。
- **帰結**: 不正なバイナリ/コード実行時も本体プロセスはパニックせず、`AppError.ExecutionError` へ安全に自動フォールバック。

### ADR-002: Lyceum バックエンドとの透過的モナド接続
- **ステータス**: 承認済 (Accepted)
- **文脈**: リモート Gemini API とローカル GGUF (Gemma) モデルの切替を意識させない透過的な推論パイプラインを確保する。
- **決定**: `Lyceum` の `LlmBackend` インタフェースを統一採用し、`Pakila` から一元的に呼び出し可能とする。

### ADR-003: 日本語 / マルチバイト文字分析と Symbol32 規格
- **ステータス**: 承認済 (Accepted)
- **文脈**: 日本語・マルチバイト文字列のトークナイズ処理における文字化けや境界切り出しエラーを防ぐ。
- **決定**: 文字コード体系を `Symbol32` / UTF-8 バイト境界安全処理に統一する。

---
**Document Status: Active & Fully Synchronized**
