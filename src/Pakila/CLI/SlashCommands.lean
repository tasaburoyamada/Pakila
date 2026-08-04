import Lean

namespace Pakila.CLI

/-- 
スラッシュコマンドの定義。
名称、説明、および入力バッファに挿入される文字列。
-/
structure SlashCommand where
  name : String
  description : String
  template : String
deriving Inhabited, BEq, Repr

/-- 利用可能なスラッシュコマンドの一覧 -/
def availableSlashCommands : List SlashCommand := [
  { name := "model",    description := "LLMモデルを切り替える", template := "/model " },
  { name := "rewind",   description := "過去の状態へ対話的に巻き戻す (Rewind TUI)", template := "/rewind" },
  { name := "config",   description := "設定を編集する", template := "/config" },
  { name := "memory",   description := "メモリ管理UIを起動する", template := "/memory" },
  { name := "export",   description := "対話履歴をMarkdownファイルへ出力する", template := "/export " },
  { name := "help",     description := "ヘルプを表示する", template := "/help" },
  { name := "clear",    description := "画面をクリアする", template := "/clear" },
  { name := "reset",    description := "セッションをリセットする", template := "/reset" },
  { name := "exit",     description := "Pakilaを終了する", template := "/exit" },
  { name := "quit",     description := "Pakilaを終了する", template := "/quit" }
]

/-- スラッシュコマンド判定用 O(1) パターンディスパッチ -/
def lookupSlashCommand (name : String) : Option SlashCommand :=
  match name with
  | "model"  => some { name := "model",    description := "LLMモデルを切り替える", template := "/model " }
  | "rewind" => some { name := "rewind",   description := "過去の状態へ対話的に巻き戻す (Rewind TUI)", template := "/rewind" }
  | "config" => some { name := "config",   description := "設定を編集する", template := "/config" }
  | "memory" => some { name := "memory",   description := "メモリ管理UIを起動する", template := "/memory" }
  | "export" => some { name := "export",   description := "対話履歴をMarkdownファイルへ出力する", template := "/export " }
  | "help"   => some { name := "help",     description := "ヘルプを表示する", template := "/help" }
  | "clear"  => some { name := "clear",    description := "画面をクリアする", template := "/clear" }
  | "reset"  => some { name := "reset",    description := "セッションをリセットする", template := "/reset" }
  | "exit"   => some { name := "exit",     description := "Pakilaを終了する", template := "/exit" }
  | "quit"   => some { name := "quit",     description := "Pakilaを終了する", template := "/quit" }
  | _        => none

/-- パースされたコマンド -/
structure ParsedCommand where
  cmd : SlashCommand
  args : List String
deriving Inhabited, Repr

/-- スラッシュコマンドをパースする (O(1) ルックアップ) -/
def parseSlashCommand (input : String) : Option ParsedCommand :=
  if input.startsWith "/" then
    let parts := input.splitOn " "
    let cmdName := (parts.head!.drop 1).toString
    let args := parts.tail
    match lookupSlashCommand cmdName with
    | some c => some { cmd := c, args := args }
    | none => none
  else
    none

end Pakila.CLI
