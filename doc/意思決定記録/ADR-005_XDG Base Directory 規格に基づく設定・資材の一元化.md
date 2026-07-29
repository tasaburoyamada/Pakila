# ADR-005: XDG Base Directory 規格に基づく設定・資材の一元化

## ステータス
承認済 (Accepted)

## コンテキスト
従来、Pakila の設定ファイル (`config.toml`) やセッション履歴 (`.pakila/sessions/`)、スキル定義がプロジェクトローカルまたは散乱したディレクトリに依存していたため、ユーザー環境での設定管理およびポータビリティに課題があった。

## 決定
- Linux/Unix の標準規格である XDG Base Directory Specification に準拠した設定・資材管理構造を採用する。
- デフォルトの設定基底ディレクトリを `$XDG_CONFIG_HOME/pakila` (未設定時は `~/.config/pakila/`) とする。
- 優先順位:
  1. `$XDG_CONFIG_HOME/pakila/config.toml` (または `~/.config/pakila/config.toml`)
  2. カレントディレクトリの `./config.toml` (プロジェクトローカル)

## 帰結
- ユーザー環境全体の共通コンフィグ・セッション・スキルが `~/.config/pakila/` 配下にスマートに一元化される。
- プロジェクトローカル設定への安全なフォールバックも維持される。
