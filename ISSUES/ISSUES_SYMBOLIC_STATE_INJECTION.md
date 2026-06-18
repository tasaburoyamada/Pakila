# イシュー: 初期プロンプトへのシンボリックステート自動注入

## 概要
`lasada` は `init` 時に、システム情報 (OS, Kernel, CPU, Mem, PWD) と共に、HV-CAD 固有のシンボリックデータ (`@CTX`, `@BIAS`, `CONCEPT`) を自動的に注入している。`pakila` ではこの初期化ロジックが未実装。

## 詳細タスク
- [x] `src/Core/PromptManager.lean`: `SysInfo` モジュールから得た情報を整形するテンプレートの実装。
- [x] `@CTX`, `@BIAS`, `CONCEPT` トークンの動的生成と、初期 `system` メッセージへの付加ロジック。
- [x] 初回起動時（履歴が空の時）のみ発火するガード条件の実装。
