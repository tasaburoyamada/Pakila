import Pakila.Plugins.Sandbox
import Lyceum.Types

open Pakila

def testSandbox : IO Unit := do
  let engine : SandboxEngine := { cwd := ".", env := [] }
  let res ← executeHost engine "echo hello"
  match res with
  | .ok "hello\n" => IO.println "✔ Integration Test (Sandbox Host): Passed"
  | .ok out => IO.eprintln s!"✖ Integration Test (Sandbox Host): Failed (Got {repr out})"; IO.Process.exit 1
  | .error e => IO.eprintln s!"✖ Integration Test (Sandbox Host): Failed ({repr e})"; IO.Process.exit 1

def main : IO Unit := testSandbox
