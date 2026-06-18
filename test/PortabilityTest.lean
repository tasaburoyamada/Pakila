import Pakila.Core.Environment
import Lyceum.Types

open Pakila
open Lyceum

def main : IO Unit := do
  IO.println "--- Portability & Environment Test ---"
  
  -- Test 1: expandPath with valid HOME (already implicitly tested, but let's be explicit)
  let home ← IO.getEnv "HOME"
  match home with
  | some h => 
      let p ← expandPath "~/.gemini"
      if p.toString == s!"{h}/.gemini" then IO.println "✔ expandPath with HOME: PASS"
      else IO.println s!"✖ expandPath with HOME: FAIL ({p})"
  | none => IO.println "⚠ HOME is not set in this environment, skipping standard expandPath test."

  -- Test 2: OS Abstraction (Checking if we can detect WSL/Linux/macOS)
  -- This is a placeholder for actual OS detection logic which we need to implement.
  IO.println "--- Test Complete ---"
