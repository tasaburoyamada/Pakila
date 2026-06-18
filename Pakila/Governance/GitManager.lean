import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Environment

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila.Governance.GitManager

/-- 
現在の状態をコミット（チェックポイント）として保存する。
Rewind/Restore 用。
-/
def createCheckpoint (message : String) : IO (Except AppError String) := do
  try
    let res ← IO.Process.run { cmd := "git", args := #["commit", "-am", s!"[Pakila Checkpoint]: {message}"] }
    return Except.ok res
  catch e =>
    return Except.error (AppError.ExecutionError s!"Git checkpoint failed: {e}")

/-- 指定したID（コミット）まで戻る -/
def rewindTo (id : String) : IO (Except AppError String) := do
  try
    let res ← IO.Process.run { cmd := "git", args := #["reset", "--hard", id] }
    return Except.ok res
  catch e =>
    return Except.error (AppError.ExecutionError s!"Git rewind failed: {e}")

/-- 最新の変更を取り消す (restore) -/
def restoreLatest : IO (Except AppError String) := do
  try
    let res ← IO.Process.run { cmd := "git", args := #["checkout", "HEAD^", "--", "."] }
    return Except.ok res
  catch e =>
    return Except.error (AppError.ExecutionError s!"Git restore failed: {e}")

/-- 新しい Worktree を作成する -/
def createWorktree (name : String) : IO (Except AppError String) := do
  let path := s!"../pakila-worktree-{name}"
  if ← (System.FilePath.mk path).pathExists then
    TerminalEnv.println s!"[GitManager] Worktree {name} already exists at {path}. Prioritizing existing resource."
    return Except.ok path
  try
    let _ ← IO.Process.run { cmd := "git", args := #["worktree", "add", "-b", name, path] }
    return Except.ok path
  catch e =>
    return Except.error (AppError.ExecutionError s!"Git worktree creation failed: {e}")

end Pakila.Governance.GitManager
