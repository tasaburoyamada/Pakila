import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference
import Pakila
import Pakila.Config.Loader
import Pakila.Core.FileInjector
import Pakila.Core.Persistence
import Pakila.Core.Summarizer
import Pakila.Governance.SelfHealer
import Pakila.Governance.Vlog
import Pakila.Governance.VlogParser

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

open Pakila

namespace ComprehensiveTests

structure MockLlmSummary where
deriving Repr, Inhabited

instance : LlmBackend MockLlmSummary where
  listModels _ := return Except.ok ["mock-v1"]
  streamChatCompletion _ _ _ := return Except.ok [Message.mkText .assistant "mock response summary"]
  streamContext _ _ _ _ := return Except.error (Lyceum.AppError.LlmError "Not implemented")

def assert (name : String) (cond : Bool) (msg : String := "") : IO Unit := do
  if cond then
    IO.println s!"[PASS] {name}"
  else
    throw (IO.userError s!"[FAIL] {name}: {msg}")

def testPersistence : IO Unit := do
  IO.println "[Test] Testing Atomic Persistence & Recovery..."
  let testFile : System.FilePath := { toString := "/tmp/pakila_persistence_test.txt" }
  let backupFile : System.FilePath := { toString := "/tmp/pakila_persistence_test.txt.bak" }
  
  -- Clean up
  let _ ← IO.FS.removeFile testFile |> (try · catch _ => pure ())
  let _ ← IO.FS.removeFile backupFile |> (try · catch _ => pure ())

  let content1 := "Session Data Version 1"
  match (← atomicWriteFile testFile content1) with
  | .ok _ => pure ()
  | .error e => throw (IO.userError s!"[Fail] Initial write failed: {repr e}")
  
  assert "Persistence (Initial Write)" (← testFile.pathExists) "File should exist"

  let content2 := "Session Data Version 2"
  match (← atomicWriteFile testFile content2) with
  | .ok _ => pure ()
  | .error e => throw (IO.userError s!"[Fail] Second write failed: {repr e}")
  
  assert "Persistence (Backup Created)" (← backupFile.pathExists) "Backup should exist"

  let _ ← IO.FS.removeFile testFile
  match (← recoverFile testFile) with
  | .ok recovered =>
      assert "Persistence (Recovery)" (recovered == content1) s!"Expected '{content1}' but got '{recovered}'"
  | .error e => throw (IO.userError s!"[Fail] Recovery failed: {repr e}")

def testProtocolConversion : IO Unit := do
  IO.println "[Test] Testing Gemini Protocol Conversion..."
  let sysMsg := Message.mkText .system "You are a helpful assistant."
  let userMsg := Message.mkText .user "Hello Gemini."
  let history := [sysMsg, userMsg]
  
  let (systemOpt, contents) ← messagesToGemini history
  
  let hasSystem := match systemOpt with
    | some sys => sys.role == "system" && sys.parts.length == 1
    | none => false
  assert "Protocol Conversion (System Instruction)" hasSystem "System message mismatch"
  
  let hasUser := contents.length == 1 && contents[0]!.role == "user"
  assert "Protocol Conversion (User Content)" hasUser "User message mismatch"

def testComprehensiveSuite : IO UInt32 := do
  try
    testPersistence
    testProtocolConversion
    return 0
  catch e =>
    IO.println s!"[CRITICAL] Comprehensive Suite Failed: {e}"
    return 1

end ComprehensiveTests
