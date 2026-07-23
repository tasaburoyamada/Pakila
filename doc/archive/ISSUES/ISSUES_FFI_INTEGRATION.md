# イシュー: 外部依存のネイティブ化 (Native FFI Integration)

## 概要
シェルコマンド（`curl`, `htmlq`, `python3` 等）の呼び出しを廃止し、Lean 4 の FFI (Foreign Function Interface) を用いた C/Rust 共有ライブラリのバインディングへ移行する。

## 詳細タスク
- [x] `src/Plugins/FFI.lean`: 外部ライブラリ（HTTP, HTML, Python C-API）とのインターフェースとなる `@[extern]` 宣言の定義。
- [ ] `WebExecutor`, `PythonExecutor` 等のロジックを、シェル呼び出しから FFI 関数呼び出しへ置換。
