# イシュー: エラー伝播メカニズムの精緻化

## 概要
`lasada` の `thiserror` を用いたエラー階層は、各実行エンジンから `Interpreter` へ戻るまでの変換プロセスにおいて、`Context` を付加する複雑な処理を行っている。`pakila` ではこのコンテキスト付きエラー伝播が不足している。

## 詳細タスク
- [x] `src/Core/Error.lean`: エラー発生時のコンテキスト付与 (Stacktrace 相当の追跡情報) を行うモナド変換の実装。
- [x] `LlmBackend` や `ExecutionEngine` から戻る `Result` 型への、実行元コンテキスト注入ロジック。
