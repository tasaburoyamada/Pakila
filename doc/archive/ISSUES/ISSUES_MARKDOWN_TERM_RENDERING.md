# Priority: Class S

# イシュー: ターミナル用 Markdown レンダリングの未実装

## 概要
`lasada` は `termimad` を用いて、LLM の応答に含まれる Markdown をコンソール上で見やすくレンダリングしている。`pakila` では Markdown が生のまま出力されるため、可読性が著しく低い。

## 詳細タスク
- [x] `src/CLI/Renderer.lean`: `termimad` 相当の Markdown 解析およびターミナル向けのカラーレンダリングの実装。
- [x] LLM からの回答ブロックにおける、コードブロック、太字、箇条書き等のターミナル描画制御。
