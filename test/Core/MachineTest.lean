import Pakila.Core.Machine
import Lyceum.Types
import Lean

open Pakila
open Lyceum

-- 単体テスト: transition 関数
def testTransition : IO Unit := do
  let s : InterpreterState := { history := [], turnCount := 0, configDir := ".", activeLlm := default, activeModelName := "", sandbox := false, sandboxLevel := .Low, vlogState := [] }
  let parts : List MessagePart := [.text "/help"]
  let (action, _) := transition s parts
  match action with
  | .ShowHelp => IO.println "✔ Unit Test (Transition Help): Passed"
  | _ => IO.eprintln "✖ Unit Test (Transition Help): Failed"; IO.Process.exit 1

def main : IO Unit := do
  testTransition
  IO.println "All Unit Tests Passed."
