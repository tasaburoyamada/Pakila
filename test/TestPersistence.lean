import Pakila.Core.Persistence
import Pakila.Core.State
import Lean

open Pakila

/-- セッション保存とリカバリをテストする -/
def testPersistence : IO Unit := do
  let sessionId := "test_session_123"
  let sessionDir := System.FilePath.mk ".pakila" / "sessions"
  
  IO.println s!"[TEST] Starting persistence test in {sessionDir}..."
  
  -- セッション状態のモック
  let state : InterpreterState := { sessionId := sessionId, vlogState := [] }
  
  -- 保存テスト
  saveSession state
  
  -- ロードテスト
  match ← loadSession sessionId with
  | .ok _ => IO.println "[TEST] Load success!"
  | .error e => IO.println s!"[TEST] Load failed: {e}"

def main : IO Unit := do
  testPersistence
