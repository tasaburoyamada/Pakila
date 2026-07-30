import Lbir
import Lean.Data.Json
import Lyceum.Types
import Lyceum.Protocol.Types
import Lyceum.Protocol.Parser
import Pakila.Core.Delegator
import Lyceum.Inference
import Pakila.Core.State

namespace Pakila

open Lyceum.Protocol

/-- 状態遷移ロジック（純粋関数コア: 履歴を参照して次のアクションを決定） -/
def transition (s : InterpreterState) (parts : List Lyceum.MessagePart) : MachineAction × InterpreterState :=
  let input := match parts.head? with | some (.text t) => t | _ => ""
  
  if input == "/quit" || input == "/exit" then
    (MachineAction.Quit, s)
  else if input.startsWith "/test_command " then
    let testCommand := (input.drop "/test_command ".length).trimAscii.toString
    (MachineAction.RunTest testCommand, s)
  else
    let userMsg : Lyceum.Message := { role := .user, parts := parts }
    let nextS := { s with history := s.history ++ [userMsg], turnCount := s.turnCount + 1 }
    
    match userMsg.role with
    | .assistant => 
        let rawText := userMsg.parts.foldl (fun acc p => match p with | .text t => acc ++ t | _ => acc) ""
        match parseActionFromText rawText with
        | some action => (action, nextS)
        | none => (MachineAction.CallLlm nextS.history, nextS)
    | _ => 
        (MachineAction.CallLlm nextS.history, nextS)

end Pakila
