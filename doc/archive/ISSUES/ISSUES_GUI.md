# イシュー: GUI操作と画面認識プラグインの未実装

## 概要
`lasada` は `xdotool`、`scrot`、`imageproc` を利用したGUI操作および画面注釈機能を持つが、`pakila` では未実装。

## 詳細タスク
- [x] `src/Plugins/Computer.lean`: `xdotool` をラップしたGUI自動操作エンジンの実装。
- [x] `src/Plugins/Vision.lean`: `image` 関連ライブラリの Lean ラッパーを用いた、画面キャプチャおよびグリッド注釈機能の実装。
- [x] `src/Core/Coordinates.lean`: 画面解像度に基づいたセル座標のマッピングロジックと、型レベルでの範囲検証。
- [x] `src/Plugins/Vision.lean`: 画面グリッドラベル描画用のフォント読み込みロジック (DejaVuSans.ttf 等のパス処理)。
