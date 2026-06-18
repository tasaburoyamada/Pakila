# Architectural Hazards: Process Lifecycle & Termination

本ドキュメントは、Pakila のプロセス終了および IPC (Inter-Process Communication) におけるデッドロックおよびハングアップリスクの監査結果である。

## 1. 識別されたハザード (Identified Hazards)

| ID | コンポーネント | 内容 | リスク |
| :--- | :--- | :--- | :--- |
| H-01 | Main.lean | `IO.Process.exit` 前の stdout/stderr フラッシュの欠如 | バッファ内に残存するデータがフラッシュされず、親プロセスとの通信がデッドロックする。 |
| H-02 | MainLoop.lean | 終了シグナル受信時の論理・物理終了の非同期 | `MachineAction.Quit` 発生時にプロセスが物理終了せず、親が wait でハングする。 |
| H-03 | TestDriver.lean | パイプ消費とプロセスの wait のデッドロック | 読み込み処理がプロセス終了をブロックし、プロセスがバッファ溢れで停止する。 |
| H-04 | ScenarioRunner.lean | タイムアウト制御の欠如 | 子プロセスが無限ループに入った場合に、テストランナー全体がハングする。 |

## 2. 対策方針 (Remediation)

- **H-01**: `Main.lean` の終了シーケンスに `IO.getStdout().flush()` を追加する。
- **H-02**: `MainLoop.lean` の終了ロジックを `IO.Process.exit` へ物理的に直結させる。
- **H-03**: `Nomos.TestDriver` をタスクベースの非同期消費モデルに改修し、バッファデッドロックを防止する。
- **H-04**: `ScenarioRunner` に物理的な `timeout` 監視を導入する。
