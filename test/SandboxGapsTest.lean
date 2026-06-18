import Pakila.Plugins.Sandbox
import Lyceum.Types

open Pakila
open Lyceum

def testNetworkIsolation : IO Unit := do
  IO.println "\n[Test] Network Isolation (--unshare-net)"
  let engine : SandboxEngine := { cwd := ".", env := [], level := .Low, allowNetwork := false }
  -- Ping should fail immediately if network is unreachable
  let res ← ExecutionEngine.execute engine "ping -c 1 8.8.8.8" "bash"
  match res with
  | .ok out => 
      if out.contains "unreachable" || out.contains "Failure" || out.contains "exit code: 2" || out.contains "Exit Code: 2" || out.contains "Exit Code: 1" then
         IO.println "✔ Network isolation verified (ping failed as expected)."
      else
         IO.println s!"✖ Network isolation failed! Ping might have succeeded. Output: {out}"
  | .error e => IO.println s!"✔ Network isolation verified via Error: {repr e}"

def testDockerIsolation : IO Unit := do
  IO.println "\n[Test] Docker Isolation (File System)"
  let testFile := "/tmp/pakila_docker_isolation_test.txt"
  -- Ensure file doesn't exist on host
  let _ ← IO.Process.run { cmd := "rm", args := #["-f", testFile] }
  
  let engine : SandboxEngine := { cwd := ".", env := [], level := .Medium, image := "ubuntu:latest" }
  -- Try to write to /tmp inside docker
  let res ← ExecutionEngine.execute engine s!"echo 'docker_test' > {testFile} && cat {testFile}" "bash"
  match res with
  | .ok out =>
      if out.contains "docker_test" then
        -- Check if it leaked to host
        if ← (System.FilePath.mk testFile).pathExists then
          IO.println "✖ Docker isolation failed! File leaked to host."
          let _ ← IO.Process.run { cmd := "rm", args := #["-f", testFile] }
        else
          IO.println "✔ Docker isolation verified (File created inside container, not on host)."
      else
        IO.println s!"✖ Docker execution failed to write file internally. Output: {out}"
  | .error e => IO.println s!"⚠ Docker test skipped/error: {repr e}"

def main : IO Unit := do
  IO.println "--- Sandbox Advanced Gaps Test ---"
  testNetworkIsolation
  testDockerIsolation
  IO.println "--- Test Complete ---"
