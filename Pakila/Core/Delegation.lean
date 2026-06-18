import Pakila.Core.Interface
import Pakila.Protocol.Types
import Pakila.Core.Types
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Delegator
import Pakila.Core.State
import Pakila.CLI.Theme

open Lyceum
open Pakila
open Pakila.Protocol
open Pakila.Core.Delegator

namespace Pakila

/-- エージェント（サブプロセス）を呼び出すスタブ実装 -/
def invokeAgent (req : AgentRequest) : IO (Except String String) := do
  pure (.ok s!"Agent {(toString (repr req.type))} finished task.")

/-- エージェント委譲アクションを処理する -/
def handleInvokeAgent (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (req : AgentRequest) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ DELEGATE: Invoking {(toString (repr req.type))}...\n")
  match ← invokeAgent req with
  | .ok res =>
      TerminalEnv.print (applyColor .green s!"✔  Sub-agent {(toString (repr req.type))} returned results.\n")
      let toolMsg : Message := { role := .tool, parts := [.toolResponse "invoke_agent" res] }
      cont.runLoop nextS
  | .error e =>
      TerminalEnv.print (applyColor .red s!"✖  Sub-agent failure: {e}\n")
      let toolMsg : Message := { role := .tool, parts := [.toolResponse "invoke_agent" s!"Error: {e}"] }
      cont.runLoop nextS

end Pakila
