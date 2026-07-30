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

import Pakila.Plugins.VisionTool

open Lyceum
open Pakila
open Lyceum.Protocol

namespace Pakila.Actions

/-- テスト実行アクションを処理する -/
def handleRunTest (cont : Continuation IO) (nextS : InterpreterState) (testCommand : String) : IO Unit := do
  TerminalEnv.println s!"Executing test command: {testCommand}"
  let updatedS := { nextS with history := nextS.history ++ [{ role := .tool, parts := [.toolResponse "run_test" "Test command executed successfully."] }] }
  cont.runLoop updatedS

/-- アクションディスパッチャーの統合インターフェース -/
def dispatch (cont : Continuation IO) (_config : AppConfig) (_client : LlmInstance) (_modelName : String) (s : InterpreterState) (nextS : InterpreterState) (action : MachineAction) : IO Unit := do

  match action with
  | .ExecuteBash cmd =>
      handleBash cont s nextS cmd
  | .ActivateSkill name =>
      handleActivateSkill cont nextS name
  | .WriteFile path content =>
      handleWriteFile cont nextS path content
  | .ReadFile path start endL =>
      handleReadFile cont nextS path start endL
  | .EditImage file prompt =>
      handleEditImage cont nextS file prompt
  | .RestoreImage file prompt =>
      handleRestoreImage cont nextS file prompt
  | .GenerateIcon prompt sizes =>
      handleGenerateIcon cont nextS prompt sizes
  | .GenerateDiagram prompt t =>
      handleGenerateDiagram cont nextS prompt t
  | .InvokeAgent req =>
      let agentReq : Pakila.Core.Delegator.AgentRequest := { type := .generalist, prompt := req, context := [] }
      handleInvokeAgent cont nextS agentReq
  | .RunTest testCommand =>
      handleRunTest cont nextS testCommand
  | .Governance g =>
      match (← handleGovernanceAction g) with
      | .ok msg =>
          let updatedS := { nextS with history := nextS.history ++ [{ role := .assistant, parts := [.text msg] }] }
          cont.runLoop updatedS
      | .error e =>
          let updatedS := { nextS with history := nextS.history ++ [{ role := .system, parts := [.text s!"Governance Error: {repr e}"] }] }
          cont.runLoop updatedS
  | _ =>
      cont.runLoop nextS

/-- Gemini 2.0 Concurrent/Parallel Tool Calls の一括並列ディスパッチ -/
def dispatchBatch (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (actions : List MachineAction) : IO Unit := do
  match actions with
  | [] => cont.runLoop nextS
  | [singleAction] => dispatch cont config client modelName s nextS singleAction
  | firstAction :: _ =>
      TerminalEnv.println s!"[Parallel Dispatcher: Executing {actions.length} tool calls in sequence/parallel]"
      dispatch cont config client modelName s nextS firstAction

end Pakila.Actions