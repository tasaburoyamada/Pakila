import Lyceum.Types
import Lyceum.Inference
import Pakila.MainLoop
import Pakila.Mock.LlmMock
import Pakila.Plugins.Bash

open Lyceum

--TEMP_MARKER--

namespace Pakila

/-- インタプリタの各ステップを独立してテストする -/
def testInterpreterStep : IO (Except AppError Unit) := do
  let mockLlm : LlmMock := {}
  let bashEngine : BashEngine := { cwd := "/", env := [] }
  let state : InterpreterState := { history := [{role := .user, content := "ls"}], vlogState := [] }
  
  let newState ← step bashEngine mockLlm state
  
  if newState.history.length > 1 then
    IO.println "Test Interpreter Step Passed"
    return Except.ok ()
  else
    return Except.error (AppError.ToolError "Test Interpreter Step Failed")

end Pakila
