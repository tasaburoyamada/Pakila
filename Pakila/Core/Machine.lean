import Lbir
import Lean.Data.Json
import Lyceum.Types

import Pakila.Core.Delegator
import Lyceum.Inference
import Pakila.Core.State
import Pakila.Protocol.Parser

namespace Pakila

/-- 状態遷移ロジック（純粋関数コア: 履歴を参照して次のアクションを決定） -/
def transition (s : InterpreterState) (parts : List Lyceum.MessagePart) : Pakila.Protocol.MachineAction × InterpreterState :=
  let input := match parts.head? with | some (.text t) => t | _ => ""
  
  if input == "/quit" || input == "/exit" then
    (Pakila.Protocol.MachineAction.Quit, s)
  else if input.startsWith "/test_command " then
    let testCommand := (input.drop "/test_command ".length).trimAscii.toString
    (Pakila.Protocol.MachineAction.RunTest testCommand, s)
  else
    -- 1. 履歴を更新
    let userMsg : Lyceum.Message := { role := .user, parts := parts }
    let nextS := { s with history := userMsg :: s.history, turnCount := s.turnCount + 1 }
    
    -- 2. 解析 (もし最後のメッセージが LLM なら解析、それ以外は LLM へ投げる)
    match userMsg.role with
    | .assistant => 
        let rawText := userMsg.parts.foldl (fun acc p => match p with | .text t => acc ++ t | _ => acc) ""
        (Pakila.Protocol.parseSrp rawText, nextS)
    | _ => 
        (Pakila.Protocol.MachineAction.CallLlm nextS.history.reverse, nextS)

end Pakila
