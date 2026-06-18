# Pakila 動作要件と依存関係 (Prerequisites & Dependencies)

Pakila は高度にネイティブ化されており、実行時の外部コマンドへの依存を最小限に抑えています。

## 1. 必須共有ライブラリ (Runtime Shared Libraries)
Pakila は以下の共有ライブラリを `dlopen` で動的にロードします。システムにこれらがインストールされている必要があります。

| ライブラリ | 役割 | 主要なパッケージ名 (Ubuntu/Debian) |
| :--- | :--- | :--- |
| **libpython3.x.so** | Python 実行エンジンの駆動 | `libpython3.10-dev` (または同等) |
| **libcurl.so.4** | HTTP/API 通信と Web 取得 | `libcurl4-openssl-dev` |
| **libwasmtime.so** | Wasm 隔離環境の実行 | `deps/wasmtime` 内に同梱済み |

※ ライブラリの場所は自動的に検索されますが、標準的なパス (`/usr/lib`, `/usr/local/lib` 等) に存在することを推奨します。

## 2. オペレーティングシステム要件 (OS Requirements)
Pakila は Linux カーネルの高度な機能を使用します。

- **Kernel**: Linux 5.x 以降を推奨。
- **System Calls**: `unshare` (隔離用), `ioctl` (端末制御), `fork/execvp` (プロセス管理), `readlink` (自己パス特定) が利用可能であること。
- **Terminal**: ANSI エスケープシーケンスに対応した TTY ターミナル。

## 3. 開発・ビルド時依存 (Build-time Dependencies)
ソースからビルドする場合、以下のツールが必要です。

- **Lean 4 / elan**: 言語ランタイムとビルドシステム (Lake)。
- **C Compiler (gcc/clang)**: ネイティブカーネル (`kernels.c`) のコンパイル用。
- **git**: ソース取得および履歴管理機能用。

## 4. 環境設定 (Configuration)
以下のいずれかの環境変数に API キーを設定することで、クラウド推論機能が有効になります。
- `GEMINI_API_KEY`
- `GOOGLE_API_KEY`
- `OPENAI_API_KEY`

---
**Note**: Pakila は現在 `timeout`, `stty`, `tput`, `grep`, `find`, `rm` などの外部コマンドを必要としません。全てネイティブ FFI に統合されています。