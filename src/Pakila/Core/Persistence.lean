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

/-- セッション状態を保存する -/
def saveSession (_s : InterpreterState) : IO Unit := do
  -- TODO: NativeEmbeddingModel の ToJson 実装後に有効化
  pure ()

/-- セッション状態をロードする -/
def loadSession (sessionId : String) : IO (Except AppError InterpreterState) := do
  let sessionDir := System.FilePath.mk ".pakila" / "sessions"
  let path := sessionDir / s!"{sessionId}.json"
  if !(← path.pathExists) then
    return Except.error (AppError.ExecutionError "loadSession: session file not found")
  
  let content ← TerminalEnv.readFile path
  match Json.parse content with
  | .ok _ =>
    return Except.error (AppError.ExecutionError "loadSession: NativeEmbeddingModel serialization pending")
  | .error e =>
    return Except.error (AppError.SerializationError e)

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

  -- 4. Remove backup file (or keep it depending on policy)
  -- For safety, we keep the backup until the next success.
  
  return Except.ok ()

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
