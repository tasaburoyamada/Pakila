# イシュー: ベクトルメモリの具体的なモデルと閾値の適合

## 概要
`lasada` の `VectorDB` は、`AllMiniLML6V2` モデルを使用し、類似度閾値を `0.5` に固定している。また、メタデータは `HashMap<String, String>` として扱われている。

## 詳細タスク
- [x] `src/Memory/VectorDB.lean`: 検索時のハードコードされた閾値 `0.5` の適用。
- [x] 埋め込みモデルの識別子として `AllMiniLML6V2` を明示し、将来的なモデル切り替えの型定義。
- [x] メタデータの型を `Lean.Data.HashMap String String` へ厳密化。
