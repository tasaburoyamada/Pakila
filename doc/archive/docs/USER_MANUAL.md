# Pakila User Manual (v0.43.0)

Pakila は、Lean 4 ベースの形式的自律型インタプリタです。数学的に証明可能な自律エージェントの構築と、物理環境における安全な隔離実行を実現します。

---

## 1. インストール (Installation)

Pakila はソースコードからのビルドを推奨します。

```bash
# ビルド
cd apps/pakila
lake build pakila:exe

# パスへのインストール
cp .lake/build/bin/pakila ~/.local/bin/
```

## 2. 設定 (Configuration)

Pakila は `config.toml` を以下の優先順位で読み込みます。

1. カレントディレクトリ: `./config.toml`
2. ユーザー設定: `~/.config/pakila/config.toml`

### 設定項目例 (`config.toml`)
```toml
llmModel = "gemini-1.5-pro"
llmApiUrl = "https://generativelanguage.googleapis.com/"
systemPrompt = "あなたは形式検証に長けた自律エージェントです。"
timeoutMs = 30000
debug = false
```

## 3. 実行モード (Execution Modes)

Pakila は対話的（Interactive）および非対話的（Non-interactive）モードをサポートします。

*   **対話モード**: `pakila` (デフォルト)
*   **非対話モード**: `pakila -p "プロンプト文字列"`

### サンドボックスと隔離 (Isolation Levels)
Pakila はセキュリティ強化のため、以下の隔離レベルをサポートします。

*   **Host**: 低い隔離（ネイティブシェル実行）
*   **Native/Sandbox**: 中程度の隔離（`unshare` による Namespace 隔離）
*   **Wasm**: 高い隔離（Wasmtime によるバイトコード実行）

実行時に自動的に適切なレベルが適用されますが、詳細な制御は `AppConfig` を通じて行います。

## 4. 基本操作 (Command Interface)

対話モードでは、`>` プロンプトに対してプロンプトを入力します。`/` で始まるスラッシュコマンドにより特殊操作が可能です。

| コマンド | 内容 |
| :--- | :--- |
| `/model [name]` | 使用する LLM モデルを切り替えます |
| `/memory` | メモリ管理UIを起動し、ナレッジベースを操作します |
| `/help` | コマンド一覧を表示します |
| `/rewind` | 過去の推論状態まで状態を巻き戻します |
| `/reset` | セッション履歴をクリアします |
| `/exit` / `/quit` | Pakila を終了します |

## 5. 開発と拡張 (Procedures for Developers)

Pakila は **「Functional Core, Imperative Shell」** パターンを採用しています。

### 新機能の実装フロー
1.  **Issue 化**: `apps/pakila/ISSUES/` に変更内容を定義します。
2.  **純粋関数コアの設計**: 推論ロジックは `Pakila.Core.Machine.transition` 内の純粋関数として実装してください。
3.  **副作用の実装**: 物理的な副作用（ファイル操作、ネットワーク、Bash実行）は `runExecution` 内の `Imperative Shell` で処理します。
4.  **検証**: `lake build` および `smoke_test` を実行し、警告（Warning）が 0 であることを確認してください。

### 形式検証ワークフロー
Pakila は Lean 4 を使用しているため、論理的な不変条件を定理として証明可能です。
*   `Pakila/Core/Machine.lean` の純粋関数に対して、`theorem` を使用して性質を証明できます。
*   ビルドプロセスで `sorry` を使用している場合、CI/ビルド設定でエラーを返すよう強制しています。

---
"Lean にバグは無いが環境との界面にはバグが潜む。" —— Pakila 開発指針より
