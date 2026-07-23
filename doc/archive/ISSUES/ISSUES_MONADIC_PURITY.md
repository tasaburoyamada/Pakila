# イシュー: 純粋関数型と状態管理の分離・洗練 (Monadic Purity)

## 概要
現在の `InterpreterState` を引数として明示的に引き回す設計から、`StateT` モナド変換子を用いた洗練された状態管理へリファクタリングする。

## 詳細タスク
- [x] `src/Core/Monad.lean`: `StateT InterpreterState IO` をベースとした `PakilaM` モナドの定義。
- [ ] `MainLoop.lean` および各実行エンジンのシグネチャを `PakilaM` を用いる形にリファクタリング。
- [ ] 副作用の厳密な分離。
