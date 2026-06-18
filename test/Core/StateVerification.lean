import Lyceum.Types
import Lyceum.Inference
import Pakila.MainLoop
import Pakila.Mock.LlmMock
import Pakila.Plugins.Bash

open Lyceum

--TEMP_MARKER--

namespace Pakila

/-- インタプリタの状態遷移をステップごとに検証するテスト -/
def verifyInterpreterStateTransitions : IO (Except AppError Unit) := do
  let mockLlm : LlmMock := {}
  let bashEngine : BashEngine := { cwd := "/", env := [] }
  let initialState : InterpreterState := { history := [{role := .user, content := "init"}], vlogState := [] }
  
  let step1 ← step bashEngine mockLlm initialState
  if step1.history.length <= initialState.history.length then
    return Except.error (AppError.ToolError "Step 1: History did not grow")
  
  IO.println "Interpreter state transitions verified."
  return Except.ok ()

end Pakila
