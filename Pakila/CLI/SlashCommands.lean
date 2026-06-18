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
deriving Inhabited

/-- 利用可能なスラッシュコマンドの一覧 -/
def availableSlashCommands : List SlashCommand := [
  { name := "model",    description := "LLMモデルを切り替える", template := "/model " },
  { name := "rewind",   description := "過去の状態へ巻き戻す", template := "/rewind" },
  { name := "config",   description := "設定を編集する", template := "/config" },
  { name := "memory",   description := "メモリ管理UIを起動する", template := "/memory" },
  { name := "help",     description := "ヘルプを表示する", template := "/help" },
  { name := "clear",    description := "画面をクリアする", template := "/clear" },
  { name := "reset",    description := "セッションをリセットする", template := "/reset" },
  { name := "exit",     description := "Pakilaを終了する", template := "/exit" },
  { name := "quit",     description := "Pakilaを終了する", template := "/quit" }
]

/-- パースされたコマンド -/
structure ParsedCommand where
  cmd : SlashCommand
  args : List String
deriving Inhabited

/-- スラッシュコマンドをパースする -/
def parseSlashCommand (input : String) : Option ParsedCommand :=
  if input.startsWith "/" then
    let parts := input.splitOn " "
    let cmdName := parts.head!.drop 1
    let args := parts.tail
    match availableSlashCommands.find? (fun c => c.name == cmdName) with
    | some c => some { cmd := c, args := args }
    | none => none
  else
    none

end Pakila.CLI
