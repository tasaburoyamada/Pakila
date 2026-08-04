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

/-- エージェント（サブプロセス）を呼び出す本実装 -/
def invokeAgent (req : AgentRequest) : IO (Except String String) := do
  match ← Pakila.Core.Delegator.invokeAgent req with
  | .ok res => pure (.ok res)
  | .error e => pure (.error s!"{e}")

/-- エージェント委譲アクションを処理する -/
def handleInvokeAgent (cont : Continuation IO) (nextS : InterpreterState) (req : AgentRequest) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ DELEGATE: Invoking {(toString (repr req.type))}...\n")
  match (← invokeAgent req) with
  | .ok res =>
      let updatedS := { nextS with history := nextS.history ++ [{ role := .assistant, parts := [.text res] }] }
      cont.runLoop updatedS
  | .error err =>
      let updatedS := { nextS with history := nextS.history ++ [{ role := .system, parts := [.text s!"Delegate Error: {err}"] }] }
      cont.runLoop updatedS




end Pakila

