import Lean
import Init.System.IO
import Init.System.FilePath
import Lyceum.Types
import Lyceum.Inference


open Lean IO System FilePath
open Lyceum

namespace Pakila

structure BashEngine where
  cwd : String
  env : List (String × Option String)
  timeoutMs : Nat := 30000 -- Default timeout in milliseconds
deriving Repr, Inhabited

instance : Lyceum.ExecutionEngine BashEngine where

  prepare _self cmd lang :=
    if lang != "bash" then
      .error (AppError.ExecutionError "Unsupported language")
    else
      .ok (Lyceum.ExecutionAction.Bash cmd)


/-- Bash execution logic using Lean's standard IO.Process library. -/
def executeBash (self : BashEngine) (cmd : String) : IO (Except AppError String) := do
    let args := #["-c", cmd]
    try
      let processResult ← IO.Process.run { cmd := "bash", args := args, cwd := self.cwd, env := self.env.toArray }
      return Except.ok processResult
    catch e =>
      return Except.error (AppError.ExecutionError s!"Bash execution failed: {e}")

end Pakila

