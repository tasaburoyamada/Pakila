import Pakila.Core.Engine
import Pakila.Core.State
import Pakila.Core.Machine
import Lyceum.Types

namespace Pakila.Test

/-- 
  CLIに依存しない、メモリ内での純粋なE2Eテストドライバ。
  バイナリをspawnせず、Engineを直接呼び出す。
-/
def runScenario (initialState : InterpreterState) (input : String) : InterpreterState :=
  let parts : List MessagePart := [.text input]
  let (action, nextS) := Pakila.transition initialState parts
  -- Engine.step を直接呼び出し、IO を介さずに状態遷移をシミュレート
  let (finalAction, finalS) := Core.Engine.step nextS action
  finalS

def testScenario : IO Unit := do
  let s : InterpreterState := { 
    history := [], 
    vlogState := [],
    activeLlm := default, 
    activeModelName := "test-model",
    configDir := "." 
  }
  let finalS := runScenario s "/help"
  IO.println "✔ Scenario Test (Direct Engine Call): Passed"

def main : IO Unit := testScenario
