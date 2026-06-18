import Lean

partial def loop : IO Unit := do
  IO.sleep 1000
  IO.println "Still waiting..."
  loop

def main : IO Unit := do
  IO.println "Wait for Ctrl+C... (Testing SIGINT handling)"
  loop
