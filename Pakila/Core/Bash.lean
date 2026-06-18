import Pakila.Core.Interface
import Pakila.Protocol.Types
import Pakila.Core.Types
import Lyceum.Inference
import Lyceum.Types
import Pakila.Governance.PolicyEngine
import Pakila.Plugins.Bash
import Pakila.Plugins.Sandbox
import Pakila.CLI.Theme
import Pakila.CLI.Prompts

open Lyceum
open Pakila
open Pakila.Protocol
open Pakila.Governance.PolicyEngine
open Pakila.CLI

--TEMP_MARKER--
--TEMP_MARKER--

namespace Pakila.Actions

open MachineAction

/-- Bash アクションを処理する -/
def handleBash (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (cmd : String) : IO Unit := do
  match enforcePolicies s (ExecuteBash cmd) with
  | Except.error e =>
      TerminalEnv.println (applyColor .red s!"✖  Policy Violation: {repr e}")
      cont.runLoop nextS
  | Except.ok _ =>
      let proceed ← if s.skipTrust then pure true else Prompts.yesNo s!"Execute bash command: {cmd}?"
      if proceed then
        TerminalEnv.print (applyColor .white s!"▶ BASH: {cmd}")
        
        let res : Except AppError String ← if s.sandbox then
          let engine : SandboxEngine := { cwd := ".", env := [], allowNetwork := false }
          match ExecutionEngine.prepare engine cmd "bash" with
          | Except.ok action => 
              match ← executeSandbox engine action with
              | Except.ok out => pure (Except.ok out)
              | Except.error e => pure (Except.error (AppError.ExecutionError s!"Sandbox failed: {repr e}"))
          | Except.error e => pure (Except.error (AppError.ExecutionError s!"Prepare failed: {repr e}"))
        else
          let engine : BashEngine := { cwd := ".", env := [] }
          match ← executeBash engine cmd with
          | Except.ok out => pure (Except.ok out)
          | Except.error e => pure (Except.error (AppError.ExecutionError s!"Bash failed: {repr e}"))
        
        TerminalEnv.print "\r\x1b[K"
        match res with
        | Except.ok output => 
            TerminalEnv.println (applyColor .green "✔ BASH RETURNED SUCCESS")
            let toolMsg : Message := { role := .tool, parts := [.toolResponse "execute_bash" output] }
            cont.runLoop { nextS with history := nextS.history ++ [toolMsg] }
        | Except.error e => 
            TerminalEnv.println (applyColor .red s!"✖ BASH FAILED: {repr e}")
            let toolMsg : Message := { role := .tool, parts := [.toolResponse "execute_bash" s!"Error: {repr e}"] }
            cont.runLoop { nextS with history := nextS.history ++ [toolMsg] }
      else
        TerminalEnv.println (applyColor .white "▶ BASH: Skipped by user")
        cont.runLoop nextS

end Pakila.Actions
