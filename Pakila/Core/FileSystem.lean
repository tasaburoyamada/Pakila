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

/-- ファイル書き込みアクションを処理する -/
def handleWriteFile (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (path : String) (content : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ WRITE: Writing {path}...\n")
  TerminalEnv.writeFile (System.FilePath.mk path) content
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "write_file" "Success"] }
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  if s.skipTrust then 
    cont.runLoop finalS
  else 
    cont.runLoop finalS

/-- ファイル読み込みアクションを処理する -/
def handleReadFile (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (path : String) (start : Option Nat) (endL : Option Nat) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ READ: Reading {path}...\n")
  let content ← TerminalEnv.readFile (System.FilePath.mk path)
  let lines := content.splitOn "\n"
  let startIdx := match start with | some s => s - 1 | none => 0
  let endIdx := match endL with | some e => e | none => lines.length
  let sliced := lines.drop startIdx |>.take (endIdx - startIdx)
  let result := String.intercalate "\n" sliced
  let toolMsg : Message := { role := .tool, parts := [.toolResponse "read_file" result] }
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

end Pakila
