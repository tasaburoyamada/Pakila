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

### 2.2. アテンションベクトル構造 (`DESIGN_SPEC.vlog`)
```
@CTX:[DOM:Pakila|SUB:Modernization|GOAL:Full_Roadmap_Completion_Gemini2_Specs]
@BIAS:{P:1.0, M:1.0, S:1.0, D:1.0, C:1.0}
@DELTA(Gemini2_Full_Modernized_Stack > Gemini_043_Legacy_Stack)
+ [StructuredOutput_OpenAPI_Schema_Enforced]
+ [Native_Thinking_Config_Separated]
+ [Parallel_Tool_Dispatching_Monad]
! [241Jobs_Full_Pass_Verified]
```
- **役割**:
  - `@CTX`: コンテクストドメイン及び達成ゴールの指定。
  - `@BIAS`: パラメータ重み・指向性バイアス。
  - `@DELTA`: 旧スタックから新スタックへの差分変化ベクトル。

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
