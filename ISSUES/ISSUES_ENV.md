# イシュー: ビルド環境および依存関係の初期化

## 概要
`lasada` には `install.sh` や `PREREQUISITES.md` が存在し、環境構築の自動化が行われている。`pakila` においても再現が必要である。

## 詳細タスク
- [x] `scripts/install.sh`: 必要な Lean 4 ツールチェーンの確認・インストール、環境変数のセットアップを行うスクリプトの作成。
- [x] `PREREQUISITES.md`: プロジェクト動作に必要な前提環境の定義。
