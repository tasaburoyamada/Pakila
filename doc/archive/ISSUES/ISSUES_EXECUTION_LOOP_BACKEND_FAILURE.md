# Issue: Execution Loop and Local Backend Failures

## 1. 概要 (Description)
`pakila run` 実行時、特定の条件下（EOF入力、履歴要約のトリガー等）で無限ループや内部データの漏洩が発生する。

## 2. 再現手順 (Reproduction)
1. `echo "動く？" | pakila run` を実行。
2. Stdin の EOF 後、無限ループが発生し、`Status: Engine connected via FFI.` が繰り返される。
3. 履歴が50件を超えると `summarizeHistory` が走り、`Pakila.Role.user:` 等の内部表現が LLM の回答に混入する。

## 3. 原因分析 (Root Cause)
1. **EOF 制御の欠如**: `Main.lean` の `loop` が空入力（EOF）で再帰を停止しない。
2. **内部データ漏洩**: `Summarizer.lean` が `repr msg.role` をプロンプトに使用しているため、型情報が LLM コンテキストに漏洩する。
3. **ローカルバックエンドの文脈消失**: `LocalCandle.lean` が履歴の最後のみを送信しており、マルチターンの対話が成立しない。
4. **プロンプトテンプレートの不在**: ローカルモデル（Gemma等）に対して適切な Chat Template が適用されておらず、モデルがプロンプト構造を誤認する。

## 4. 期待される挙動 (Expected Behavior)
- EOF 入力時に正常終了すること。
- 要約時に内部型情報（`Pakila.Role.*`）が漏洩しないこと。
- ローカルバックエンドで過去の履歴が考慮されること。
- モデルごとの Chat Template が適用されること。

## 5. 修正方針 (Remediation)
- `Main.lean`: `getLine` の空チェックによる終了処理の追加。
- `Summarizer.lean`: `repr` ではなく人間可読な形式（"User", "Assistant" 等）への変更。
- `LocalCandle.lean`: 履歴全体の結合処理の実装。
- `PromptManager.lean` 等: Chat Template 適用ロジックの導入。
