import Lyceum.Inference
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Monad
import Pakila.Core.State
import Pakila.MainLoop

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

open Pakila

/-- モック用実行エンジン: 特定のコマンドに反応する -/
structure MockEngine where
deriving Repr, Inhabited

instance : ExecutionEngine MockEngine where
  execute _ cmd _ := do
    if cmd == "echo success" then
      return Except.ok "command_success_output"
    else
      return Except.error (AppError.ExecutionError "command_failed")

/-- モック用LLMバックエンド: 1回目はBashコマンドを出し、2回目は完了報告を出す -/
structure MockLlm where
deriving Repr, Inhabited

instance : LlmBackend MockLlm where
  listModels _ := return Except.ok ["mock-v1"]
  streamChatCompletion _ history _ := do
    let lastMsg := (history.getLast? |>.map (fun m => m.content)).getD ""
    if lastMsg.contains "command_success_output" then
      return Except.ok [Message.mkText .assistant "Task completed successfully."]
    else if history.length == 1 then
      return Except.ok [Message.mkText .assistant "I will run: ```bash\necho success\n```"]
    else
      return Except.error (AppError.LlmError "Unexpected state")

def testAutonomousLoop : IO (Except String Unit) := do
  let engine : MockEngine := {}
  let client : MockLlm := {}
  
  let initialState : InterpreterState := {
    history := [Message.mkText .user "Start task"],
    vlogState := [],
    sessionId := "test"
  }
  
  let (result, finalState) ← runPakilaM (step engine client) initialState
  
  IO.println s!"Final History Length: {finalState.history.length}"
  for msg in finalState.history do
    IO.println s!"- {repr msg.role}: {msg.content}"

  match result with
  | .ok _ =>
      -- 履歴が [User(Start), Assistant(Run Bash), User(Output), Assistant(Completed)] になっているか確認
      if finalState.history.length != 4 then
        return Except.error s!"Expected history length 4, got {finalState.history.length}"
      
      let lastMsg := finalState.history.getLast!
      if !(lastMsg.content.contains "completed") then
        return Except.error s!"Loop did not finish correctly. Last msg: {lastMsg.content}"
      
      return Except.ok ()
  | .error e => return Except.error s!"Loop failed with error: {repr e}"

def main : IO Unit := do
  IO.println "=== Pakila Autonomous Loop Test Suite ==="
  match (← testAutonomousLoop) with
  | .ok _ => IO.println "[PASS] AutonomousLoop"
  | .error e => IO.println s!"[FAIL] AutonomousLoop: {e}"
