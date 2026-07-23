# イシュー: ベクトルデータベースの初期化とパス管理

## 概要
`lasada` の `VectorDB::new` では、`~/.config/lasada/vectors.json` という固定パスを使用し、ディレクトリがなければ自動生成するロジックがある。`pakila` ではこの初期化ロジックの移植が必要。

## 詳細タスク
- [x] `src/Memory/VectorDB.lean`: `HOME` 環境変数を取得し、`~/.config/pakila/vectors.json` を特定するロジックの実装。
- [x] ディレクトリが存在しない場合に `fs::create_dir_all` 相当の機能を用いて自動作成するロジック。
