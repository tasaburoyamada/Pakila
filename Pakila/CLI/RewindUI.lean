import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.History
import Pakila.CLI.Prompts
import Pakila.CLI.Terminal
import Pakila.CLI.Theme
import Pakila.Core.Environment

open Lyceum
open Pakila
open Pakila.CLI.Prompts

--TEMP_MARKER--

namespace Pakila.CLI.RewindUI

/-- 
視覚的な履歴ブラウザ (Esc Esc で起動する TUI)
過去のターンを上下キーでプレビューし、復元ポイントを選択する。
-/
def runRewindBrowser (configDir : System.FilePath) : IO (Option String) := do
  TerminalEnv.println "--- Pakila History Browser (Rewind TUI) ---"
  let history ← Pakila.CLI.History.loadHistory configDir
  if history.isEmpty then
    TerminalEnv.println "No history available."
    return none
  
  TerminalEnv.println "Select checkpoint to rewind:"
  let entries := history.reverse
  let options := entries.map (fun s => s.take 50 |>.toString)
  
  let choice ← selectOption "Select entry:" options
  match choice with
  | some i => return some s!"HEAD~{i}"
  | none => return none

end Pakila.CLI.RewindUI
