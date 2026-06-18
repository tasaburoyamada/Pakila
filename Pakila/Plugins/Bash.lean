import Lyceum.Inference
import Lyceum.Types
import Pakila.Plugins.FFI

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

namespace Pakila

structure BashEngine where
  cwd : String
  env : List (String × String)
  timeoutMs : Nat := 30000
deriving Repr, Inhabited

instance : ExecutionEngine BashEngine where
  prepare _self cmd lang :=
    if lang != "bash" then
      .error (AppError.ExecutionError "Unsupported language")
    else
      .ok (Lyceum.ExecutionAction.Bash cmd)

/-- 実際の Bash 実行ロジック (Native FFI) -/
def executeBash (self : BashEngine) (cmd : String) : IO (Except AppError String) := do
    let timeoutSec := ((self.timeoutMs + 999) / 1000).toUInt32
    try
      let output ← Plugins.FFI.executeWithTimeout "bash" #["-c", cmd] timeoutSec
      return Except.ok output
    catch e =>
      return Except.error (AppError.ExecutionError s!"Native execution failed: {e}")

end Pakila
