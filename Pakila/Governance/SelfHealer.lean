import LeanTensor.Math.Native
import LeanTensor.Math.Ops
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Environment

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

def verifyEngine : IO Unit := do
  TerminalEnv.println "[Self-Healer]: Verifying LeanTensor Physical Engine..."
  
  if LeanTensor.Native.hasAvx512 () then
    TerminalEnv.println "[Self-Healer]: AVX-512 Instruction Set DETECTED. Using high-performance path."
  else
    TerminalEnv.println "[Self-Healer]: AVX-512 NOT found. Falling back to generic C kernels."

  let a : LeanTensor.Tensor [2, 2] := { val := #[1.0, 2.0, 3.0, 4.0], prop := by rfl }
  let b : LeanTensor.Tensor [2, 2] := { val := #[5.0, 6.0, 7.0, 8.0], prop := by rfl }
  let res := LeanTensor.matmul a b
  
  TerminalEnv.println s!"[Self-Healer]: MatMul test result: {res.val}"
  TerminalEnv.println "[Self-Healer]: Physical engine is ONLINE."

end Pakila
