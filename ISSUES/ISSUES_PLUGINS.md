# イシュー: プラグインシステムの未実装とダミー実装

## 概要
`BashEngine` および `LlmClient` が現状ではダミー実装または機能不足の状態である。`lasada` と同等の外部環境連携を実現する必要がある。

## 詳細タスク
- [x] `BashEngine`: `tokio` のような非同期実行環境におけるコマンド実行と、ストリームの正確な行単位解析の実装。
- [x] `LlmClient`: OpenAI API 互換のストリーム受信（`streamChatCompletion`）の実装。`tiktoken` 等を用いたトークンカウントの Lean 移植。
- [x] `LlmClient`: `HttpClient` 実装の具体化。現在ハードコードされているダミー応答を、実API通信に差し替える。
