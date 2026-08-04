import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.History
import Pakila.CLI.Theme
import Pakila.CLI.SlashCommands
--import Pakila.CLI.TerminalBase -- 削除 (TerminalIOに移動)
import Pakila.Core.Environment
import Pakila.Plugins.FFI

import Pakila.CLI.TerminalIO -- TerminalEnv IO インスタンスをインポート

open Lyceum
open Pakila
open Pakila.CLI
-- open Pakila.CLI.TerminalBase -- 削除
open Pakila.CLI.TerminalIO
open Pakila.CLI.History

namespace Pakila

deriving instance Inhabited for IO.FS.DirEntry

/-- カスタムReadLineの実装 (汎用版: 履歴管理＋スラッシュコマンド補完・サジェスト付き) -/
def readLineWithHistory {m : Type → Type} [Monad m] [TerminalEnv m] [MonadFinally m] [MonadLiftT IO m] (prompt : String) (configDir : System.FilePath) : m (Option String) := do
  let _ ← loadHistory configDir
  TerminalEnv.print prompt
  let line ← TerminalEnv.readLine
  let trimmed := line.trimAscii.toString

  if trimmed.startsWith "/" then
    let filtered := availableSlashCommands.filter (fun c => ("/" ++ c.name).startsWith trimmed || trimmed == "/")
    match filtered with
    | [] => pure ()
    | _ =>
        let names := filtered.map (fun c => "/" ++ c.name)
        TerminalEnv.println s!"\x1b[38;5;242m💡 Available commands: {String.intercalate ", " names}\x1b[0m"

  if !trimmed.isEmpty then
    appendHistory configDir trimmed
  return line


