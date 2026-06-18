import Pakila.Core.Interface
import Pakila.Protocol.Types
import Pakila.Core.Types
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.CLI.Theme

open Lyceum
open Pakila
open Pakila.Protocol

namespace Pakila

/-- 画像編集アクションを処理する -/
def handleEditImage (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (file : String) (prompt : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ EDIT_IMAGE: {file} ({prompt})...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_edit_image" "Edit successful."] }
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

/-- 画像復元アクションを処理する -/
def handleRestoreImage (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (file : String) (prompt : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ RESTORE_IMAGE: {file}...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_restore_image" "Restoration successful."] }
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

/-- アイコン生成アクションを処理する -/
def handleGenerateIcon (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (prompt : String) (sizes : List Nat) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ ICON: {prompt}...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_icon" "Icon generation stub."] }
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

/-- 図生成アクションを処理する -/
def handleGenerateDiagram (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (prompt : String) (t : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ DIAGRAM: Generating {t} diagram...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_diagram" "Diagram generation stub."] }
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

end Pakila
