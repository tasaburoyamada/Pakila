# イシュー: サンドボックス隔離の修正と WASM 実行の完全統合

## 1. 現状と課題 (Current Status)
- **サンドボックス失敗**: `SmokeTest` において `executeNativeLow` (bwrap代替の `unshare` 実装) が空の出力を返し、正常に動作していない。
- **WASM 実装の不完全性**: `kernels.c` に `lean_wasm_execute` は実装されているが、`Sandbox.lean` ではスタブのままであり、`MainLoop.lean` からの呼び出しも限定的である。
- **構造的一貫性の欠如**: `MainLoop.lean` の `runExecution` において `Wasm` や `Docker` が "not implemented" となっており、`SandboxEngine` との機能乖離がある。

## 2. 解決策 (Proposed Solutions)
- **[A] ネイティブ隔離の修正**: `kernels.c` の `lean_unshare_execute` に `CLONE_NEWUSER` を追加し、非特権ユーザーでも名前空間の隔離が正しく動作するように修正する。
- **[B] WASM 統合の完遂**: `Sandbox.lean` の `executeWasm` をスタブから `Pakila.wasmExecute` の呼び出しに置き換え、`IsolationLevel.High` を物理的に有効化する。
- **[C] MainLoop の堅牢化**: `runExecution` を `SandboxEngine` または `Dispatcher` 経由の正規の隔離ロジックに統合し、「構造的堅牢性 (Structural Robustness)」を向上させる。

## 3. 期待される結果 (Expected Outcome)
- `SmokeTest` の全項目（Sandbox, WASM を含む）がパスすること。
- `/run` コマンド等において、WASM プラグインや隔離された Bash 実行が決定論的に動作すること。

## 4. 評価基準 (Evaluation Criteria)
- [x] `SmokeTest` で Test 1 (Sandbox) が `SB_OK` を出力すること。
- [x] `SmokeTest` で Test 5 (WASM) が `WASM Execution Successful` を出力すること。
- [x] `MainLoop.lean` の `runExecution` から "not implemented" のスタブが排除されていること。 (WASM実装済み, Dockerは継続)
