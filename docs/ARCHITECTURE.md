# pakila アーキテクチャ設計

本ドキュメントは、Rust ベースの `lasada` からの機能移転を前提とした、Lean 4 によるインタプリタエンジン `pakila` のアーキテクチャ定義である。

## 1. 全体構成 (System Overview)
`pakila` は、証明可能な型システムの上に構築された自律型インタプリタである。

*   **L1 (演算レイヤー)**: 実行環境 (`ExecutionEngine`)。Bash, Python 等の具体的な副作用を伴う実行を定義する。
*   **L2 (推論レイヤー)**: LLM バックエンド (`LlmBackend`)。状態に基づく推論とコマンド生成を担う。
*   **L3 (ガバナンスレイヤー)**: `.vlog` 解析器。HV-CAD 哲学に基づくステート管理と、意思決定の検証を行う。

## 2. コアインターフェースの Lean 定義 (Core Abstractions)

### 2.1 型定義とエラーハンドリング
Rust の `AppError` は Lean の `Inductive` 型として定義する。

```lean
inductive AppError where
  | LlmError : String -> AppError
  | ExecutionError : String -> AppError
  | ConfigError : String -> AppError
  | Timeout : AppError
```

### 2.2 LLM バックエンド (`LlmBackend`)
`LlmBackend` トレイトは、Lean の型クラスまたは依存注入可能な構造体として定義し、IO モナド内での実行を強制する。

```lean
structure Message where
  role : String
  content : String
  -- 画像やツールコールは適宜 Option 型で定義

class LlmBackend where
  streamChatCompletion (history : List Message) : IO (Except AppError (List Message))
```
※Rust のストリーミング・非同期処理については、Lean 4 の IO モナドおよび副作用の制約内で再設計する。

### 2.3 実行エンジン (`ExecutionEngine`)
実行エンジンは、ステートフルな副作用をカプセル化する。

```lean
class ExecutionEngine where
  execute (code : String) (language : String) : IO (Except AppError String)
```

## 3. HV-CAD 統合戦略
`.vlog` ファイルは、Lean のデータ構造としてパースする。推論の結果は、常にこのデータ構造による制約を受けた `Message` リストとして生成されなければならない。

*   **状態の不変性**: 推論ループの各ステップで、現在の `@BIAS` および `@CONCEPT` は Lean の環境に注入される。
*   **自律的修復**: `ExecutionEngine` の戻り値が `ExecutionError` の場合、即座に `.vlog` にエラー情報を追記し、再推論を行う（再帰関数による再推論プロセス）。

## 4. 証明戦略 (Proof Strategy)
*   全ての副作用を伴う実装（`IO` 型）を除き、状態遷移ロジックはピュアな関数として実装し、その振る舞いの正しさを Lean で証明する。
*   特にインタプリタの終了条件と、`.vlog` 更新ルールのべき等性に関しては定理を構築する。

*注記: Rust の非同期ストリームは、Lean の再帰関数ベースの対話型入出力へと変換し、検証可能な処理フローへと再定義する。*
