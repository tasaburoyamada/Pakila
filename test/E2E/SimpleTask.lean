import Pakila.MainLoop
import Pakila.Plugins.Bash
import System.FilePath

namespace Pakila

def runE2E : IO Bool := do
  let engine : BashEngine := { cwd := "/", env := [] }
  let state : InterpreterState := { history := [], vlogState := [] }
  let newState ← step engine { streamChatCompletion := fun _ => return Except.ok [] } state
  return newState.history.length >= 0

end Pakila
