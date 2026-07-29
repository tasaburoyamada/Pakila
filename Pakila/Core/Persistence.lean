import Pakila.Core.Types
import Pakila.Core.Interface
import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.Governance.Vlog

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

open Lean hiding Message

/-- 一時ファイルを用いた原子的なファイル書き込み -/
def atomicWriteFile (path : System.FilePath) (content : String) : IO (Except AppError Unit) := do
  let tempPath := System.FilePath.mk (path.toString ++ ".tmp")
  let backupPath := System.FilePath.mk (path.toString ++ ".bak")

  -- 1. Write to temp file
  TerminalEnv.writeFile tempPath content

  -- 2. Create backup of original file (if exists)
  if (← path.pathExists) then
    TerminalEnv.rename path backupPath
  
  -- 3. Rename temp file to target path
  TerminalEnv.rename tempPath path

  return Except.ok ()

/-- セッション状態を保存する -/
def saveSession (s : InterpreterState) : IO Unit := do
  let sessionDir := System.FilePath.mk ".pakila" / "sessions"
  let _ ← IO.FS.createDirAll sessionDir
  let path := sessionDir / s!"{s.sessionId}.json"
  let historyJson := toJson (s.history.map (fun msg => msg.content))
  let obj := Json.mkObj [
    ("sessionId", Json.str s.sessionId),
    ("history", historyJson)
  ]
  let _ ← atomicWriteFile path obj.pretty

/-- セッション状態をロードする -/
def loadSession (sessionId : String) : IO (Except AppError InterpreterState) := do
  let sessionDir := System.FilePath.mk ".pakila" / "sessions"
  let path := sessionDir / s!"{sessionId}.json"
  if !(← path.pathExists) then
    return Except.error (AppError.ExecutionError "loadSession: session file not found")
  
  let content ← TerminalEnv.readFile path
  match Json.parse content with
  | .ok json =>
    match json.getObjValAs? String "sessionId" with
    | .ok id =>
      return Except.ok {
        history := [],
        vectorDb := ∅,
        vlogState := [],
        embeddingModel := default,
        sessionId := id,
        interactive := true,
        executionMode := .Interactive,
        configDir := ".pakila",
        activeLlm := default,
        activeModelName := ""
      }
    | .error e => return Except.error (AppError.SerializationError e)
  | .error e =>
    return Except.error (AppError.SerializationError e)

/-- 破損したファイルからのリカバリ (バックアップから復元) -/
def recoverFile (path : System.FilePath) : IO (Except AppError String) := do
  let backupPath := System.FilePath.mk (path.toString ++ ".bak")
  if (← backupPath.pathExists) then
    TerminalEnv.println s!"[Persistence] Recovering {path} from backup."
    let content ← TerminalEnv.readFile backupPath
    TerminalEnv.writeFile path content
    return Except.ok content
  else
    return Except.error (AppError.IoError s!"No backup file found for {path}")

end Pakila
