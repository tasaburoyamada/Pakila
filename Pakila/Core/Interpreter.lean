import Pakila.Core.Machine
import Pakila.Core.State
import Pakila.CLI.Terminal
import Lyceum.Protocol.Types -- New import
import Pakila.Core.Bash
import Pakila.Plugins.Sandbox
import Lyceum.Inference.Gemma.Backend
import Pakila.Core.Primitives
import Batteries.Lean.Json
import Lyceum.Core.Environment

open Lyceum.Protocol -- New open statement
open Pakila.Protocol -- Added open
open Lean.Json
open Lyceum.Core.Environment

namespace Pakila

/-- 物理アクションの実行層: バグはこの関数にのみ集約される -/
def runAction (action : MachineAction) (dispatcher : Dispatcher) (activeLlm : LlmInstance) [TerminalEnv IO] : IO (Except String String) := do
  match action with
  | .Quit => pure (Except.ok "Quit")
  | .CallLlm msgs => do
      match ← Lyceum.LlmBackend.streamChatCompletion activeLlm msgs none with
      | Except.ok (responseMsgs : List Lyceum.Message) =>
          let rawText := responseMsgs.foldl (fun acc (m : Lyceum.Message) => acc ++ m.content) ""
          let structuredResponse := parseStructuredLlmResponse rawText
          pure (Except.ok (toString (Lean.toJson structuredResponse))) -- Return JSON string
      | Except.error e => pure (Except.error s!"LLM Error: {repr e}")
  | .ExecuteBash cmd => 
      -- Bash 実行は IO
      let engine : BashEngine := { cwd := ".", env := [] }
      match ← Pakila.executeBash engine cmd with
      | Except.ok out => pure (Except.ok out)
      | Except.error e => pure (Except.error s!"Bash error: {repr e}")
  | .WriteFile path content =>
      -- ファイル操作は IO
      TerminalEnv.writeFile (System.FilePath.mk path) content
      pure (Except.ok "Success")
  | .ReadFile path .. =>
      -- ファイル読み込みは IO
      match ← TerminalEnv.readFile path with
      | content => pure (Except.ok content)
  | .Governance _ => pure (Except.ok "Governance action executed")
  | _ => pure (Except.ok "Action not implemented in Interpreter layer")

end Pakila
