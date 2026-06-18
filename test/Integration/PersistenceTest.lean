import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.Governance.Vlog

open Lyceum

--TEMP_MARKER--

open Pakila
open Lean hiding Message

def runTest (name : String) (test : IO (Except String Unit)) : IO Unit := do
  IO.println s!"Running test: {name}..."
  match (← test) with
  | .ok _ => IO.println s!"[PASS] {name}"
  | .error e => IO.println s!"[FAIL] {name}: {e}"

/-- SessionState: 保存と読み込みの整合性テスト -/
def testSessionPersistence : IO (Except String Unit) := do
  let testFile := "test_session.json"
  let state : InterpreterState := {
    history := [
      Message.mkText .system "Sys",
      { role := .user, parts := [.text "User", .image "image/png" [0x01].toByteArray] }
    ],
    vlogState := [.Bias 0.1 0.2 0.3 0.4 0.5],
    sessionId := "persistence_test"
  }
  
  -- 1. シリアライズ
  let json := toJson state
  IO.FS.writeFile testFile json.pretty
  
  -- 2. デシリアライズ
  let content ← IO.FS.readFile testFile
  match Json.parse content with
  | .ok jsonIn =>
      match (fromJson? jsonIn : Except String InterpreterState) with
      | .ok stateIn =>
          if stateIn.sessionId != state.sessionId then return Except.error "SessionID mismatch"
          if stateIn.history.length != state.history.length then return Except.error "History length mismatch"
          -- Vlog ステートの復元確認
          match stateIn.vlogState with
          | .Bias p _ _ _ _ :: _ => if p != 0.1 then return Except.error "Vlog bias mismatch"
          | _ => return Except.error "Vlog state missing"
      | .error e => return Except.error s!"FromJson failed: {e}"
  | .error e => return Except.error s!"Json parse failed: {e}"

  IO.FS.removeFile testFile
  return Except.ok ()

def main : IO Unit := do
  IO.println "=== Pakila Persistence & Serialization Test Suite ==="
  runTest "SessionPersistence" testSessionPersistence
