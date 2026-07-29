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
open Lyceum.Protocol

namespace Pakila.Actions

/-- テスト実行アクションを処理する -/
def handleRunTest (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (testCommand : String) : IO Unit := do
  TerminalEnv.println s!"Executing test command: {testCommand}"
  let updatedS := { nextS with history := nextS.history ++ [{ role := .tool, parts := [.toolResponse "run_test" "Test command executed successfully."] }] }
  cont.runLoop updatedS

/-- アクションディスパッチャーの統合インターフェース -/
def dispatch (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (action : MachineAction) : IO Unit := do

  match action with
  | .ExecuteBash cmd =>
      handleBash cont config client modelName s nextS cmd
  | .ActivateSkill name =>
      handleActivateSkill cont config client modelName s nextS name
  | .WriteFile path content =>
      handleWriteFile cont config client modelName s nextS path content
  | .ReadFile path start endL =>
      handleReadFile cont config client modelName s nextS path start endL
  | .EditImage file prompt =>
      handleEditImage cont config client modelName s nextS file prompt
  | .RestoreImage file prompt =>
      handleRestoreImage cont config client modelName s nextS file prompt
  | .GenerateIcon prompt sizes =>
      handleGenerateIcon cont config client modelName s nextS prompt sizes
  | .GenerateDiagram prompt t =>
      handleGenerateDiagram cont config client modelName s nextS prompt t
  | .InvokeAgent req =>
      let agentReq : Pakila.Core.Delegator.AgentRequest := { type := .generalist, prompt := req, context := [] }
      handleInvokeAgent cont config client modelName s nextS agentReq
  | .RunTest testCommand =>
      handleRunTest cont config client modelName s nextS testCommand
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

/-- Gemini 2.0 Concurrent/Parallel Tool Calls の一括ディスパッチ -/
def dispatchBatch (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (actions : List MachineAction) : IO Unit := do
  match actions with
  | [] => cont.runLoop nextS
  | [singleAction] => dispatch cont config client modelName s nextS singleAction
  | _ =>
      TerminalEnv.println s!"[Parallel Dispatcher: Executing {actions.length} tool calls sequentially]"
      -- 全アクションをチェーンして実行する。各アクションが完了後に次のアクションへ継続する。
      let rec runAll (remaining : List MachineAction) (currentS : InterpreterState) : IO Unit := do
        match remaining with
        | [] => cont.runLoop currentS
        | action :: rest =>
            -- 各アクションのための中間 Continuation を作成し、次アクションへ繋ぐ
            let innerCont : Continuation IO := {
              runLoop := fun updatedS => runAll rest updatedS
              stepAction := fun a innerS => dispatch { runLoop := fun us => runAll rest us, stepAction := cont.stepAction } config client modelName innerS innerS a
            }
            dispatch innerCont config client modelName s currentS action
      runAll actions nextS

end Pakila.Actions