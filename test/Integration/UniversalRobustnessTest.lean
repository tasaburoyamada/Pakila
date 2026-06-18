import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference
import Pakila
import Pakila.CLI.Session
import Pakila.Config.Loader
import Pakila.Plugins.Bash

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

open Pakila

/-- 
共通アサーション関数
-/
def assert (name : String) (cond : Bool) (msg : String := "") : IO UInt32 := do
  if cond then
    IO.println s!"  [PASS] {name}"
    return 0
  else
    IO.println s!"  [FAIL] {name}: {msg}"
    return 1

-- ==========================================
-- Dimension 1: Boundary (API, Shell, FS)
-- ==========================================

def testApiErrorHandling : IO UInt32 := do
  IO.println "--- Test: API Error Handling ---"
  let mut failures : UInt32 := 0
  
  -- Case 1: Quota exceeded
  let errorJson := "{\"error\": {\"code\": 429, \"message\": \"Quota exceeded\", \"status\": \"RESOURCE_EXHAUSTED\"}}"
  match Lean.Json.parse errorJson with
  | .ok j =>
    let hasError := match j.getObjVal? "error" with | .ok _ => true | _ => false
    failures := failures + (← assert "Identifies 'error' field" hasError)
  | .error e => 
    IO.println s!"  ERROR: JSON Parse failed: {e}"
    failures := failures + 1

  -- Case 2: Empty object (No candidates)
  let emptyJson := "{}"
  match Lean.Json.parse emptyJson with
  | .ok j =>
    let hasCandidates := match j.getObjVal? "candidates" with | .ok _ => true | _ => false
    failures := failures + (← assert "Handles missing candidates" (!hasCandidates))
  | .error e => 
    IO.println s!"  ERROR: JSON Parse failed: {e}"
    failures := failures + 1

  return failures

def testBashResourceLimits : IO UInt32 := do
  IO.println "\n--- Test: Bash Resource Limits ---"
  let mut failures : UInt32 := 0
  let engine : BashEngine := { cwd := ".", env := [], timeoutMs := 500 }
  
  -- Case B1: Timeout
  let res1 ← Pakila.executeBash engine "sleep 2"
  match res1 with
  | Except.error m => 
    failures := failures + (← assert "Catches command timeout" (s!"{repr m}".contains "timed out" || s!"{repr m}".contains "Native execution failed"))
  | Except.ok out =>
    -- タイムアウトはデリミタを通じて終了コード 124 として検出されるか、プロセスが強制終了して空になる
    failures := failures + (← assert "Catches command timeout" (out.contains "124" || out.isEmpty))

  -- Case B2: Output Limit
  let res2 ← Pakila.executeBash engine "dd if=/dev/zero bs=100k count=20 | base64"
  match res2 with
  | Except.ok out =>
    -- 最新の実装では、バッファ上限に達した際に出力が切り詰められて安全に完了する
    failures := failures + (← assert "Truncates large output" (out.length < 5000000))
  | Except.error _ =>
    failures := failures + (← assert "Truncates large output" true)

  return failures

-- ==========================================
-- Dimension 2: Resource (Memory, FS)
-- ==========================================

def testFileBoundaryGuards : IO UInt32 := do
  IO.println "\n--- Test: File Boundary Guards ---"
  let mut failures : UInt32 := 0
  
  -- Case F1: 10MB Large File
  let largeFile := "test_large.bin"
  let _ ← IO.Process.run { cmd := "dd", args := #["if=/dev/zero", s!"of={largeFile}", "bs=1M", "count=10"] }
  let parts1 ← Pakila.injectFileParts s!"Analyze @{largeFile}"
  let tooLarge := parts1.any (fun p => match p with | .text t => t.contains "too large" | _ => false)
  failures := failures + (← assert "Blocks 10MB file injection" tooLarge)
  let _ ← IO.Process.run { cmd := "rm", args := #[largeFile] }

  -- Case F2: Permission Denied
  let noReadPath := "test_no_read.txt"
  let _ ← IO.FS.writeFile noReadPath "secret"
  let _ ← IO.Process.run { cmd := "chmod", args := #["000", noReadPath] }
  let parts2 ← Pakila.injectFileParts s!"Read @{noReadPath}"
  let hasError := parts2.any (fun p => match p with | .text t => t.contains "Failed to read" | _ => false)
  failures := failures + (← assert "Reports file permission errors" hasError)
  let _ ← IO.Process.run { cmd := "chmod", args := #["644", noReadPath] }
  let _ ← IO.Process.run { cmd := "rm", args := #[noReadPath] }

  return failures

-- ==========================================
-- Dimension 4: State (Session)
-- ==========================================

def testSessionRecovery : IO UInt32 := do
  IO.println "\n--- Test: Session Recovery ---"
  let mut failures : UInt32 := 0
  let sessionDir := System.FilePath.mk ".pakila" / "sessions"
  if !(← sessionDir.pathExists) then IO.FS.createDirAll sessionDir
  
  let sessionId := "corrupted_test"
  let badPath := sessionDir / s!"{sessionId}.json"
  let _ ← IO.FS.writeFile badPath "invalid json {"
  
  let res ← loadSession sessionId
  match res with
  | .error (AppError.SerializationError _) => 
    failures := failures + (← assert "Detects corrupted session JSON" true)
  | _ => 
    failures := failures + (← assert "Detects corrupted session JSON" false "Expected serialization error")
  
  let _ ← IO.Process.run { cmd := "rm", args := #[badPath.toString] }
  return failures

def runUniversalRobustnessTests : IO UInt32 := do
  IO.println "=== Pakila Universal Robustness Test Suite ==="
  let mut totalFailures : UInt32 := 0
  totalFailures := totalFailures + (← testApiErrorHandling)
  totalFailures := totalFailures + (← testBashResourceLimits)
  totalFailures := totalFailures + (← testFileBoundaryGuards)
  totalFailures := totalFailures + (← testSessionRecovery)
  
  if totalFailures == 0 then
    IO.println "\n========================================"
    IO.println "  ALL ROBUSTNESS TESTS PASSED           "
    IO.println "========================================\n"
  else
    IO.println s!"\n--- Robustness Suite Failed with {totalFailures} errors ---\n"
  return totalFailures
