import Lbir
import Nomos.Laws
import Lyceum.Types
import Pakila.Core.State
import Pakila.Core.Machine

namespace Pakila.Test.BlackboxTraceTest

open Nomos
open Pakila

/-- 初期状態定義 -/
def initialInterpreterState : InterpreterState := {
  history := []
  vlogState := []
  activeLlm := .remote default
}

/-- Nomos 不変律適合 Agent アダプター -/
def pakilaAgent : Nomos.Agent InterpreterState (List Lyceum.MessagePart) Lyceum.Protocol.MachineAction where
  initialState := initialInterpreterState
  step s input := Pakila.transition s input

/-- ブラックボックストレース検証 -/
def testMachineBlackboxTrace : IO Bool := do
  let trace : Trace InterpreterState (List Lyceum.MessagePart) Lyceum.Protocol.MachineAction := [
    (initialInterpreterState, [.text "/quit"], Lyceum.Protocol.MachineAction.Quit)
  ]
  return IsConsistentTrace pakilaAgent trace



end Pakila.Test.BlackboxTraceTest
