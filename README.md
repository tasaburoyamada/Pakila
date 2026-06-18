# Pakila: Formalized Autonomous Interpreter

[![Language](https://img.shields.io/badge/language-Lean_4-orange.svg)](https://leanprover.github.io/)
[![Architecture](https://img.shields.io/badge/architecture-HV--CAD-blue.svg)](./ARCHITECTURE.md)
[![License](https://img.shields.io/badge/license-Apache_2.0-green.svg)](./LICENSE)

**Pakila** は、定理証明支援系 **Lean 4** を用いて再構築された、証明可能な正しさを備えた自律型インタプリタエンジンです。先行プロジェクト `lasada` の意志を継ぎつつ、 Any-To-Any マルチモーダル対応と、物理環境における圧倒的な堅牢性を数理的に融合させています。

## 🌟 主要な特徴 (Key Features)

- **数理的検証**: 状態遷移の矛盾や無限ループを Lean 4 の型システムで制御。
- **Any-To-Any マルチモーダル**: テキスト、画像、音声、動画、ツールコールを統合。
- **防弾仕様の環境界面**: 物理タイムアウト、メモリリミッター、例外の強制捕捉をOS層で確立。
- **HV-CAD 統治**: `.vlog` ベクトルステートによる、AI の「確率分布」へのダイレクトな価値注入。
- **ハイブリッド推論**: Gemini API とローカル GGUF モデルを環境に応じて自律選択。

## 📚 ドキュメント (Documentation)

- **[PROJECT_DEFINITION.md](./PROJECT_DEFINITION.md)**: プロジェクトの目的、原則、ロードマップ。
- **[ARCHITECTURE.md](./ARCHITECTURE.md)**: Lean 4 による詳細なシステム設計。
- **[HOW_TO_USE.md](./HOW_TO_USE.md)**: セットアップと使用方法。
- **[ORIGIN.md](./ORIGIN.md)**: プロジェクト名の由来。
- **[DEVELOPMENT_HISTORY.md](./DEVELOPMENT_HISTORY.md)**: 開発動機と解決策の変遷。
- **[ISSUES.md](./ISSUES.md)**: 既知の課題と将来の展望。

## 🚀 クイックスタート (Quick Start)

1. **ビルド**: `lake build pakila:exe`
2. **インストール**: `cp .lake/build/bin/pakila ~/.local/bin/`
3. **実行**: `pakila run`

---
"Lean にバグは無いが環境との界面にはバグが潜む。" —— Pakila 開発指針より
