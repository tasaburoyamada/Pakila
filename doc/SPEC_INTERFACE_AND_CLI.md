---
@doc_governor: SPECIFICATION
@priority: CRITICAL
@override: TRUE
---

# Pakila インターフェース & CLI 機能仕様書 (Pakila Interface & CLI Specification)

## 1. 概要 (Overview)

本ドキュメントは、`Pakila` におけるユーザーインターフェース（CLI / CognitiveUX）、Gemini 2.0 規格順次モダナイズ仕様、並びに Wasm サンドボックスの動的ツールディスパッチ仕様を規定する。

---

## 2. Gemini 2.0 モダナイゼーション仕様

`Pakila` は Gemini 2.0 規格に対応した高密度推論・ツール呼び出しパイプラインを備える。

### 2.1. Native Structured Output & OpenAPI Schema
- **仕様**: `Lyceum.Protocol.Types.structuredLlmResponseSchema` により AST 型および出力スキーマを API レベルで完全拘束。
- **目的**: 文字列パースエラーや不正フォーマットの発生を物理的に排除する。

### 2.2. Native Thinking Config
- **仕様**: `thinking_config` (`thinkingBudget`, `includeThoughts`) および思考ログ `GeminiPart.thought` をネイティブ制御。
- **挙動**: 思考プロセスをユーザーインターフェース（CognitiveUX）上で段階的に可視化・可視制御。

### 2.3. Parallel Tool Dispatching Monad
- **仕様**: `Pakila.Plugins.Dispatcher` 及び `Pakila.Actions.dispatchBatch` モナドによる 1 ターン複数アクションの一括並列ディスパッチ。
- **効果**: ツール実行待ち時間を極小化し、最大並列性で非同期タスクを処理。

---

## 3. CLI 及び CognitiveUX 仕様

### 3.1. コマンドライン引数 (`Pakila.CLI.ArgParser`)
- `pakila run`: 標準対話モードでのインタプリタ起動。
- `pakila exec <script>`: 非対話スクリプト実行。
- `pakila config`: 設定ファイルのバリデーション及び表示。

### 3.2. CognitiveUX 描画エンジン (`Pakila.CLI.Renderer` / `Theme`)
- **レスポンシブ Terminal 描画**: UTF-8 / `Symbol32` 安全なマルチバイト表示。
- **テーマ制御**: Sleek Dark Mode, Modern ANSI カラーパレット。
- **インタラクティブフィードバック**: 思考プロセス、並列ツール実行状況のリアルタイムプログレス表示。

---

## 4. Wasmtime サンドボックス分離仕様

### 4.1. 外部プラグイン実行モデル
- **インターフェース**: `Pakila.Core.Wasm`
- **制限事項**:
  - メモリ上限設定（メモリリーク防止）
  - 物理タイムアウト制御
  - シグナル/パニックの安全捕捉と `AppError` 変換

---
*Document Status: Active & Fully Synchronized with doc-governor*
