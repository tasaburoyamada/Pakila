---
@doc_governor: GOVERNANCE
@priority: CRITICAL
@override: TRUE
---

# Pakila 統治 & セキュリティ仕様書 (Pakila Governance & Security Specification)

## 1. 概要 (Overview)

本ドキュメントは、`Pakila` における `.vlog` ベクトルステート統治、HV-CAD 原則に基づく AI 制御、並びに物理境界における防腐・セキュリティ制御仕様を規定する。

---

## 2. `.vlog` ベクトルステート統治

### 2.1. 概要と役割 (`Pakila.Governance.Vlog`)
`.vlog`（Vector Log）ファイルは、AI の推論確率分布に対する「人間（L3）からのダイレクトな価値評価ベクトル」を固定するための宣言型仕様定義ファイルである。

### 2.2. 二層分離ベクトルステート構造 (`Pakila.Governance.VlogSpec`)
`.vlog` 統治は「物理トークン/パラメータ制御（Physical Layer）」と「プロンプトコンテクスト制御（Semantic Layer）」の二層分離型データ構造として定義される。

```lean
structure PhysicalVlogConfig where
  temperature     : Option Float
  topP            : Option Float
  maxTokens       : Option Nat
  logitBias       : List (String × Float)
  stopSequences   : List String

structure SemanticVlogConfig where
  domain          : String
  subDomain       : String
  goal            : String
  mandatory       : List String
  concepts        : List String
```

- **役割**:
  - `PhysicalVlogConfig`: API / C++ FFI レベルで推論エンジンに直結する物理パラメータ（Logit Bias, Stop Sequences, Temperature）。
  - `SemanticVlogConfig`: システムプロンプト空間へ安全かつ一元的に注入される宣言的文脈・ハード制約。
  - `formatVlogState`: 一次元バッファリングと `String.join` による $O(N)$ パフォーマンスを保証。

---

## 3. ガバナンスコンポーネント仕様

### 3.1. SelfHealer (`Pakila.Governance.SelfHealer`)
- **機能**: 実行時エラーおよび境界外入力検知時の自動自己修復モジュール。
- **原則**: 単なるエラーの握りつぶしを厳禁とし、型安全なフォールバック状態への決定論的移行を行う。

### 3.2. McpManager & SkillManager (`Pakila.Governance.McpManager` / `SkillManager`)
- **機能**: Model Context Protocol (MCP) 及び外部スキルの読み込み・権限統治。
- **セキュリティ**: 危険なツール呼び出し（非サンドボックス化実行など）に対するプロミキュアスアクセスの制限。

---

## 4. 物理境界防腐規則 (Boundary Anti-Corruption Rules)

1. **環境依存の遮断**: OS/アーキテクチャ依存を型クラス・アダプターに閉じ込め、コアロジックへの波及を防止。
2. **外部Pushの厳格禁止**: 自動処理におけるリモートリポジトリ（GitHub等）への `git push` を禁止。
3. **履歴優先の真実確認**: ファイル紛失・不整合発生時は Git 履歴 (`git log`) を客観的証拠として優先参照。

---
*Document Status: Active & Fully Synchronized with doc-governor*
