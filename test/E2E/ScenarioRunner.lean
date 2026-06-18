import Nomos.TestDriver
import Lyceum.Types

open Nomos.TestDriver

def runPakilaScenario : IO Unit := do
  IO.println "Starting scenario..."
  let tc : TestCase := {
    binaryPath := "./.lake/build/bin/pakila",
    input := "/help\n/quit\n",
    expected := "Shortcuts"
  }
  IO.println s!"Running binary at: {tc.binaryPath}"
  let res ← runTest tc
  IO.println "Test finished."
  if res.success then
    IO.println "✔ Acceptance Test (Scenario Basic): Passed"
  else
    IO.eprintln s!"✖ Acceptance Test (Scenario Basic): Failed\nOutput: {res.output}"
    IO.Process.exit 1

def main : IO Unit := runPakilaScenario
