import Pakila.Plugins.Sandbox
import Lyceum.Types

open Pakila
open Lyceum

def testBwrap : IO Unit := do
  IO.println "--- Testing Bwrap (Low) ---"
  let engine : SandboxEngine := { cwd := ".", env := [], level := .Low }
  IO.println s!"Engine level: {repr engine.level}"
  let res ← ExecutionEngine.execute engine "echo 'hello from bwrap'; exit 0" "bash"
  match res with
  | .ok out => IO.println s!"Success: {repr out}"
  | .error e => IO.println s!"Error: {repr e}"

def testDocker : IO Unit := do
  IO.println "--- Testing Docker (Medium) ---"
  let engine : SandboxEngine := { cwd := ".", env := [], level := .Medium, image := "ubuntu:latest" }
  let res ← ExecutionEngine.execute engine "echo 'hello from docker'; exit 0" "bash"
  match res with
  | .ok out => IO.println s!"Success: {repr out}"
  | .error e => IO.println s!"Error: {repr e}"

def testWasm : IO Unit := do
  IO.println "--- Testing Wasm (High) ---"
  let engine : SandboxEngine := { cwd := ".", env := [], level := .High }
  let res ← ExecutionEngine.execute engine "nop" "wasm"
  match res with
  | .ok out => IO.println s!"Success: {out}"
  | .error e => IO.println s!"Expected Error: {repr e}"

def main : IO Unit := do
  testBwrap
  testDocker
  testWasm
