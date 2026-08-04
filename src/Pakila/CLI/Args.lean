import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference

open Lyceum

--TEMP_MARKER--

namespace Pakila

/-- 承認モード (Approval Mode) -/
inductive ApprovalMode where
  | default   -- 破壊的操作のみ確認
  | auto_edit -- 編集は自動、Bashは確認
  | yolo      -- 全て自動
  | plan      -- 実行禁止 (Read-only)
deriving Repr, BEq, Inhabited, Lean.ToJson, Lean.FromJson

/-- 出力形式 -/
inductive OutputFormat where
  | text
  | json
  | streamJson
deriving Repr, BEq, Inhabited, Lean.ToJson, Lean.FromJson

structure RunArgs where
  query : List String := []
  model : Option String := none
  prompt : Option String := none
  promptInteractive : Option String := none
  session : Option String := none
  approvalMode : ApprovalMode := .default
  worktree : Option String := none
  sandbox : Bool := false
  outputFormat : OutputFormat := .text
  policies : List String := []
  skipTrust : Bool := false
  verbose : Bool := false
deriving Repr, BEq, Inhabited

inductive Subcommand where
  | run (args : RunArgs)
  | mcp (args : List String)
  | skills (args : List String)
  | hooks (args : List String)
  | config
  | session (name : String)
  | listSessions
  | deleteSession (name : String)
  | listExtensions
  | help
  | version
deriving Repr, BEq, Inhabited

structure Args where
  model : Option String := none
  debug : Bool := false
  session : Option String := none
  approvalMode : ApprovalMode := .default
  prompt : Option String := none
  promptInteractive : Option String := none
  apiUrl : Option String := none
  sandbox : Bool := false 
  worktree : Option String := none
  policies : List String := []
  outputFormat : OutputFormat := .text
  skipTrust : Bool := false
  systemPrompt : Option String := none
deriving Repr, BEq, Inhabited

end Pakila
