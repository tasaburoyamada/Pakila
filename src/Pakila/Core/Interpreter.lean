import Pakila.Core.Machine
import Pakila.Core.State
import Pakila.CLI.Terminal
import Lyceum.Protocol.Types -- New import
import Pakila.Core.Bash
import Pakila.Plugins.Sandbox
import Lyceum.Inference
import Pakila.Core.Primitives

import Lean.Data.Json
import Lyceum.Core.Environment

import Pakila.Plugins.Dispatcher
import Pakila.Plugins.Sandbox

import Pakila.Core.Governance

open Lyceum.Protocol -- New open statement
open Pakila.Protocol -- Added open
open Lean.Json
open Lyceum.Core.Environment
open Lyceum

namespace Pakila

/-- 物理アクションの実行層: バグはこの関数にのみ集約される -/
def runAction (action : MachineAction) (dispatcher : Dispatcher) (activeLlm : LlmInstance)
    (llmOptions : Option Lyceum.LlmRequestOptions := none) [TerminalEnv IO] : IO (Except String String) := do
  match action with
  | .Quit => pure (Except.ok "Quit")
  | .CallLlm msgs => do
      match ← Lyceum.LlmBackend.streamChatCompletion activeLlm msgs llmOptions with
      | Except.ok (responseMsgs : List Lyceum.Message) =>
          let rawText := responseMsgs.foldl (fun acc (m : Lyceum.Message) => acc ++ m.content) ""
          let structuredResponse := parseStructuredLlmResponse rawText
          pure (Except.ok (toString (Lean.toJson structuredResponse)))
      | Except.error e => pure (Except.error s!"LLM Error: {repr e}")
  | .ExecuteBash cmd => 
      if dispatcher.useSandbox then
        match Lyceum.ExecutionEngine.prepare dispatcher.sandboxEngine cmd "bash" with
        | Except.ok prepAction => 
            match ← Pakila.executeSandbox dispatcher.sandboxEngine prepAction with
            | Except.ok out => pure (Except.ok out)
            | Except.error e => pure (Except.error s!"Sandbox error: {repr e}")
        | Except.error e => pure (Except.error s!"Prepare sandbox error: {repr e}")
      else
        match ← Pakila.executeBash dispatcher.bashEngine cmd with
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
  | .Governance govAction =>
      match ← Actions.handleGovernanceAction govAction with
      | .ok msg => pure (Except.ok msg)
      | .error e => pure (Except.error s!"Governance Error: {repr e}")
  | _ => pure (Except.ok "Action processed.")

end Pakila
