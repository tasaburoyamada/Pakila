import Pakila.Protocol.Types
import Pakila.Core.Types
import Pakila.Core.Interface
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Bash
import Pakila.Core.Delegation
import Pakila.Core.FileSystem
import Pakila.Core.Generative
import Pakila.Core.Governance
import Pakila.Core.Memory
import Pakila.Core.Skills
import Pakila.Core.State

open Lyceum
open Pakila
open Pakila.Protocol

--TEMP_MARKER--

namespace Pakila.Actions

/-- アクションディスパッチャーの統合インターフェース -/
def dispatch (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (action : MachineAction) : IO Unit := do
  match action with
  | MachineAction.ExecuteBash cmd =>
      handleBash cont config client modelName s nextS cmd
  | MachineAction.ActivateSkill name =>
      handleActivateSkill cont config client modelName s nextS name
  | MachineAction.WriteFile path content =>
      handleWriteFile cont config client modelName s nextS path content
  | MachineAction.ReadFile path start endL =>
      handleReadFile cont config client modelName s nextS path start endL
  | MachineAction.EditImage file prompt =>
      handleEditImage cont config client modelName s nextS file prompt
  | MachineAction.RestoreImage file prompt =>
      handleRestoreImage cont config client modelName s nextS file prompt
  | MachineAction.GenerateIcon prompt sizes =>
      handleGenerateIcon cont config client modelName s nextS prompt sizes
  | MachineAction.GenerateDiagram prompt t =>
      handleGenerateDiagram cont config client modelName s nextS prompt t
  | MachineAction.InvokeAgent req =>
      let agentReq : Pakila.Core.Delegator.AgentRequest := { type := .generalist, prompt := req, context := [] }
      handleInvokeAgent cont config client modelName s nextS agentReq
  | MachineAction.RunTest testCommand =>
      TerminalEnv.println s!"Executing test command: {testCommand}"
      (← IO.getStdout).flush
      (← IO.getStderr).flush
      IO.eprintln s!"DEBUG: Test command '{testCommand}' processed."
      (← IO.getStderr).flush
      pure ()
  | _ => 
      TerminalEnv.println s!"Action not fully migrated: {repr action}"
      cont.runLoop nextS

end Pakila.Actions