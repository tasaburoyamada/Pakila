# イシュー: SRP プロトコルにおけるナラティブ圧縮と状態管理

## 概要
`Gemini CLI` 仕様に基づき、インタプリタは 3〜10 ターンに一度 `update_topic` を発行し、ストーリーの要約を更新しなければならない。また、ターン末尾の `[Status]` 行に厳密な状態 (`COMPLETED`, `IN_PROGRESS` 等) を反映させる。

## 詳細タスク
- [x] `src/CLI/Protocol.lean`: ターン数をカウントし、一定間隔で要約更新を促す、または自動発行するロジック。
- [x] `InterpreterState` に `turnCount` と `currentStatus` を追加。
- [x] 状態遷移に応じた `[Status]` 行の動的生成。
- [x] 各ターンの自律検証結果を `[Summary]` にマージする詳細ロジック。
