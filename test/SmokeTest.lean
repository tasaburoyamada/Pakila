import Nomos.TestDriver
import Pakila.Core.State
import Pakila.Core.Wasm
import Pakila.Memory.NativeEmbedding
import Pakila.Memory.VectorDB
import Lyceum.Types

open Nomos.TestDriver

/--
Pakila Smoke Test ported to Nomos TestDriver.
-/
def main : IO Unit := do
  IO.println "==============================================="
  IO.println "   PAKILA CORE SMOKE TEST (Nomos Driver)   "
  IO.println "==============================================="

  -- 既存のバイナリをNomosドライバーで制御するケース
  let tests : List TestCase := [
    { binaryPath := "/home/pc241139/sandbox/kaihatsu/apps/pakila/.lake/build/bin/pakila", args := ["--test", "/quit"], input := "", expected := "Exiting Test Mode (inputs exhausted).", timeoutSec := 30 }
  ]

  for tc in tests do
    let res ← runTest tc
    IO.println s!"DEBUG: Test Result - Success: {res.success}, Output: '{res.output}', Error: '{res.error.getD "None"}'"
    if res.success then
      IO.println s!"  ✔ SUCCESS: {tc.binaryPath} passed."
    else
      IO.println s!"  ✖ FAILURE: {tc.binaryPath} failed. Error: {res.error.getD "None"}"
      IO.Process.exit 1

  IO.println "==============================================="
  IO.println "   SMOKE TEST COMPLETE   "
  IO.println "==============================================="
