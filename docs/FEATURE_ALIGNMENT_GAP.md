# Pakila vs Gemini CLI 0.43.0: Feature Alignment Gap

本ドキュメントは、Gemini CLI 0.43.0 の全機能を Pakila が網羅するためのギャップ分析結果を記録したものである。

## 1. 静的フラグ (CLI Options)

| カテゴリ | フラグ | 重要度 | 状況 (Pakila) | 備考 |
| :--- | :--- | :--- | :--- | :--- |
| ガバナンス | `--approval-mode` | **P0** | **実装済** | default, auto_edit, yolo, plan の4モード |
| ガバナンス | `--policy` / `--admin-policy` | **P0** | 引数実装済 | Nomos 連携のロジック統合中 |
| セキュリティ | `--skip-trust` | P1 | 実装済 | 状態保持に対応 |
| 隔離実行 | `--worktree` | P1 | **物理実装済** | Git worktree 自動作成機能 |
| 隔離実行 | `--sandbox` | P1 | 引数実装済 | Wasm/Docker 連携のトリガー |
| 入出力 | `--output-format` | P1 | **実装済** | text, json, stream-json への対応 |
| セッション | `--session-file` / `--session-id` | P2 | 引数実装済 | 外部ファイルからのロード |
| セッション | `--list-sessions` / `--delete-session` | P2 | アクション実装済 | 管理用サブコマンド |
| 拡張性 | `--extensions` / `--list-extensions` | P2 | アクション実装済 | 読み込むプラグインの動的フィルタリング |

## 2. 対話型スラッシュコマンド (Slash Commands)

| コマンド | 重要度 | 状況 (Pakila) | 機能概要 |
| :--- | :--- | :--- | :--- |
| `/rewind` | **P0** | **物理実装済** | Git HEAD^ へのハードリセットによるロールバック |
| `/restore` | **P0** | **物理実装済** | Git checkout による特定ファイル/全変更の復元 |
| `/memory` | **P1** | アクション実装済 | 物理的なコンテキスト制御ロジックを統合中 |
| `/settings` | P1 | アクション実装済 | TUI エディタのプレースホルダ |
| `/chat` | P2 | アクション実装済 | 履歴ブラウザのプレースホルダ |
| `/copy` | P2 | アクション実装済 | 最後の回答をクリップボードにコピー |
| `/tools` / `/agents` | P2 | アクション実装済 | 有効なツールやエージェントのステータス表示 |

## 3. コンテキスト & 環境 (Contextual Features)

| 機能 | 重要度 | 状況 (Pakila) | 備考 |
| :--- | :--- | :--- | :--- |
| **File Injection (`@`)** | **P0** | **実装済** | `@path` を検知し、内容をメッセージに自動注入 |
| **Shell Passthrough (`!`)** | **P1** | **実装済** | プロンプトから直接 Bash を実行可能 |
| **gitignore 準拠** | P1 | 暫定 | `.geminiignore` を含む階層的な無視ルールの完全適用 |

## 4. プロトコル (Strategic Response Protocol)

| 機能 | 重要度 | 状況 (Pakila) | 備考 |
| :--- | :--- | :--- | :--- |
| **SRP 5 Section 分離** | **P0** | 暫定 | Topic, Intent, Body, Summary, Status の物理的な分離生成 |
| **stream-json スキーマ** | P1 | **実装済** | チャンクごとの JSON プロトコル完全同期 |

---

## 結論とアクションプラン

1. **短期 (P0)**: 主要機能の物理実装完了。
2. **中期 (P1)**: Nomos 連携による `--policy` の数理的強制。
3. **仕上げ**: `/settings` や `/memory` の TUI/物理ロジックの作り込み。
