# Pakila 使用方法 (How to Use)

## 1. 動作要件 (Prerequisites)
- **Lean 4 / Lake**: プロジェクトのビルドと実行に必要。
- **cURL**: Gemini API 等との外部通信に使用。
- **base64**: マルチモーダルデータの処理に使用。
- **timeout**: Bash コマンドの物理実行制限に使用。

## 2. セットアップ (Setup)

### ビルドとインストール
プロジェクトルートで以下のコマンドを実行します。
```bash
cd pakila
lake build pakila:exe
cp .lake/build/bin/pakila ~/.local/bin/pakila
```

### 設定の配置
`config.toml` は、以下の優先順位で読み込まれます。
1.  `./config.toml` (カレントディレクトリ)
2.  `~/.config/pakila/config.toml` (ユーザー設定)

## 3. 基本的な使い方

### 自律対話モードの起動
```bash
pakila run
```

### セッションの管理
以前の会話履歴や HV-CAD ステートを継続する場合：
```bash
pakila run --session <session_name>
```

### コンフィグの確認
現在の設定（モデル、URL、コンテキストのロード状況）を表示：
```bash
pakila config
```

## 4. 特殊コマンドとマルチモーダル入力

### ファイル注入 (@演算子)
プロンプト内で `@path/to/file` を記述することで、内容を動的にロードします。
- **テキストファイル**: 内容がコンテキストに挿入されます。
- **画像・音声・バイナリ**: Any-To-Any モデルへのマルチモーダルパーツとして自動送信されます。
例: `AI、この画像の内容を音声で説明して。 @sample.jpg`

### HV-CAD ステートの注入
`.vlog` ファイルがカレントディレクトリまたは上位ディレクトリに存在する場合、自動的にロードされ、AI のアテンションが制御されます。

## 5. 終了方法
対話ループ内で `exit` または `quit` と入力して終了します。
