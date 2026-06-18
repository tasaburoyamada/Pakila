import Pakila.Core.Machine
import Pakila.MainLoop
import Pakila.Config.Loader

open Pakila

def testParallelExecution : IO Unit := do
  let action := MachineAction.ParallelActions [
    MachineAction.ReadFile "Pakila.lean" none none,
    MachineAction.GlobSearch "*.lean" (some ".") false
  ]
  IO.println "--- Testing Parallel Execution ---"
  -- executeAction を用いて並列実行をシミュレート
  -- 本来は MainLoop.stepAction がこれを処理する
  IO.println "ParallelActions action created."
  
def main : IO Unit := do
  testParallelExecution
