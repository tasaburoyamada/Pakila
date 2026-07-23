# イシュー: サンドボックス隔離によるセキュリティ強化

## 概要
`lasada` は `--sandbox` オプションにより実行環境を隔離する意図がある。`pakila` では外部コマンド実行の隔離基盤がない。

## 詳細タスク
- [x] `src/Plugins/Sandbox.lean`: bwrap / Docker / Wasm (Stub) によるハイブリッド隔離エンジン。
- [x] `MainLoop.lean` との統合および `IsolationLevel` による動的切り替えの実装。
- [ ] 隔離された実行環境における、権限分離の形式証明。
