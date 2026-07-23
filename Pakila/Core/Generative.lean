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
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_edit_image" s!"Edited image {file}"] }
  let updatedS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop updatedS

/-- 画像復元アクションを処理する -/
def handleRestoreImage (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (file : String) (prompt : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ RESTORE_IMAGE: {file}...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_restore_image" s!"Restored image {file}"] }
  let updatedS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop updatedS

/-- 画像生成全般アクションを処理する -/
def handleGenerateImage (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (prompt : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ GENERATE_IMAGE: {prompt}...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_image" s!"Generated image for prompt: {prompt}"] }
  let updatedS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop updatedS

/-- アイコン生成アクションを処理する -/
def handleGenerateIcon (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (prompt : String) (sizes : List Nat) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ GENERATE_ICON: {prompt}...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_icon" s!"Generated icon for prompt: {prompt}"] }
  let updatedS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop updatedS

/-- ダイアグラム生成アクションを処理する -/
def handleGenerateDiagram (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (prompt : String) (diagramType : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ GENERATE_DIAGRAM: {prompt} ({diagramType})...\n")
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_diagram" s!"Generated diagram for prompt: {prompt}"] }
  let updatedS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop updatedS

end Pakila
