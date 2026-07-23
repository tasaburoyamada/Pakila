# Pakila Strategy: Local-First 'Orchestration Hub'

## 1. 核心理念 (Core Philosophy)
Pakilaは、**「全能の Local Engine」**を中心に据えた分散協調型エージェントへと進化する。Local Engine（メインモデル）は単なる推論機ではなく、全体の「指揮官（Orchestrator）」であり、他の専門モデルやツールへの指示、評価、統合を自律的に行う。

## 2. 物理リソースの管理形態
リソースのライフサイクルに基づいて、以下の二系統で管理する。

1.  **Shared MCP (Persistent/Multi-session)**
    *   **特徴**: 長期稼働する MCP サーバーとして常駐。全セッションで共用される重い推論モデル（高パラメーターモデル等）。
    *   **管理**: セッション外で起動・監視し、Pakila Engine がソケット通信経由でツールコールを投げる。
2.  **On-Demand Local Models (Transient/On-demand)**
    *   **特徴**: 視覚モデルや音声モデルなど、特定のタスク発生時にのみメモリにロードし、実行後に開放する。
    *   **管理**: Orchestrator (Local Engine) がタスク完了時またはメモリ不足時に動的にロード/アンロードを指示。

## 3. オーケストレーション・デザイン (Updated)

```mermaid
graph TD
    User((User)) --> LocalEngine[Local Engine (Orchestrator)]
    LocalEngine -->|gRPC/Stdio| SharedMCP[Shared Persistent MCP]
    LocalEngine -->|Dynamic Load/Unload| TransientLocal[Transient Specialized Models (Vision/Audio)]
    LocalEngine -->|Fallback| RemoteGemini[Remote Gemini]
    SharedMCP -->|Result| LocalEngine
    TransientLocal -->|Result| LocalEngine
```

## 4. 実装要件
*   **Self-Reflective Dispatching**: Local Engine が自分の能力限界（知識不足、計算コスト、専門性）をメタプロンプトで判断できるよう、Tool-Calling プロトコルを強化する。
*   **Tool-Augmented Memory**: 専門モデルの結果を、Local Engine の VectorDB に自動的に地層化（Embedding）するパイプラインを構築する。
*   **物理的統一**: 音声・画像モデルの推論結果を「純粋なテキスト」として統合するのではなく、Pakilaの `MessagePart` としての型安全性を維持する。

## 3. ハイブリッド・ディスパッチャの新基準 (Routing Heuristics)

| タスク特性 | 選択バックエンド | 判定理由 |
| :--- | :--- | :--- |
| **機密/個人情報を含む** | Local Engine | 外部流出の物理的遮断。 |
| **ツール実行 (MCP)** | Local MCP | 物理環境との最短界面。 |
| **一般的な質問 (< 2k tokens)** | Local Engine | 物理リソースの有効活用。 |
| **複雑な設計/広域探索** | Remote Gemini | クラウドのパラメーター数による突破。 |

## 4. 物理的実装要件 (Physical Requirements)
*   **メモリ局所性**: ベクトルDB（RAG）は常にローカルに保持し、クラウドへのコンテキスト送信は「最小限の要約」に絞る。
*   **MCPの自律管理**: Pakila自身がローカルMCPサーバーを起動・停止・制御する権限を持つ。
*   **量子化最適化**: CPUリソースを最大化するため、AVX-512による量子化演算（Q4_K, Q8_0）を標準とする。

## 5. 最終目標 (Ultimate Goal)
「インターネットから切断された状態でも、開発と統治を継続できる数学的に正しいエージェント」の実現。
