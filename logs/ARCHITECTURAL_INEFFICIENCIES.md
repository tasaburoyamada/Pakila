# Architectural Inefficiencies Audit (Pakila)

本ドキュメントは、Pakila のコードベースにおける「パフォーマンスおよび物理メモリ使用効率」を低下させている実装の網羅的リストである。これらは現在、論理的な正しさには影響しないが、長期稼働時や高負荷時にエージェントの推論レイテンシを劣化させる原因となる。

## 1. 文字列・リスト結合の計算量 ($O(N^2)$ パターン)
これらは、リストや文字列の末尾へ継続的に `++` を行うことで発生する。

- **Pakila/CLI/Renderer.lean**:
  - `msg.parts.foldl (fun acc p => acc ++ t)`: メッセージの結合が頻繁なため、トークン数が増えると O(N^2) の再割り当てが発生する。
- **Pakila/Governance/Vlog.lean**:
  - `nodes.foldl (fun acc n => acc ++ vlogNodeToTokens n)`: 履歴ログが長くなると著しい劣化を招く。
- **Pakila/CLI/ArgParser.lean**:
  - `acc.policies ++ [p]` および `acc.query ++ [q]`: リストの末尾結合は O(N) であり、引数が多い場合に非効率。
- **Pakila/CLI/Renderer.lean**:
  - String.intercalate 以外の ++ による連結が多用されており、文字列の結合コストが蓄積している。

## 2. 冗長なメモリ割り当て
- **Pakila/MainLoop.lean**:
  - stepAction 等で nextS := { s with history := ... } とレコード更新を行う際、構造体のコピーが発生している。巨大な履歴リストを含んでいる場合、このコピーは物理的なメモリ負荷となる。

## 3. その他の非効率性
- **Pakila/Plugins/LocalLeanTensor.lean**:
  - historyToPrompt の foldl による再構築処理。エージェントが長時間運用されると、この計算コストが推論の度に指数関数的に重くなる。

---
監査担当の結論:
これら全ての非効率な実装は、純粋な foldl (· ++ ·) ではなく、List を一旦作成してから String.join に渡す、あるいは Array を用いたバッファリングを行うことで O(N) への改善が可能である。また、状態の更新は永続データ構造を前提とした実装を徹底することで最小限のコピーに留めるべきである。
