import Pakila.Core.Types
import Pakila.Core.Interface
import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila.Core.Delegator

open Lean hiding Message

/-- 委譲先のサブエージェントの種類 -/
inductive AgentType where
  | codebaseInvestigator
  | generalist
  | cliHelp
deriving Repr, BEq, ToJson, FromJson, Inhabited

instance : ToString AgentType where
  toString t := match t with
    | .codebaseInvestigator => "codebase_investigator"
    | .generalist => "generalist"
    | .cliHelp => "cli_help"

/-- サブエージェントへのリクエスト -/
structure AgentRequest where
  type : AgentType
  prompt : String
  context : List Message
deriving ToJson, FromJson, Repr

/-- 
サブエージェントの実行。
新しい pakila プロセスを立ち上げ、非同期で実行する。
-/
def invokeAgent (req : AgentRequest) : IO (Except AppError String) := do
  TerminalEnv.println (s!"[Delegator]: Spawning sub-agent ({repr req.type})...")
  
  let tempFile := s!".pakila_agent_input_{req.type}.json"
  let reqJson := toJson req
  TerminalEnv.writeFile (System.FilePath.mk tempFile) reqJson.compress

  -- ネイティブバイナリパスの取得と実行 (Self-Execution)
  let exePath ← Pakila.Plugins.FFI.getExecutablePathNative ()

  let child ← IO.Process.spawn {
    cmd := exePath
    args := #["--prompt-interactive", tempFile]
    stdout := .piped
    stderr := .piped
  }
  
  let out ← child.stdout.readToEnd
  let err ← child.stderr.readToEnd
  let status ← child.wait
  
  try IO.FS.removeFile tempFile catch _ => pure ()
  
  if status == 0 then
    return Except.ok out
  else
    return Except.error (AppError.ExecutionError s!"Sub-agent failed with status {status}. Stderr: {err}")

end Pakila.Core.Delegator
