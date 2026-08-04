import Lyceum.Types
import Lyceum.Inference
import Nomos.Contract
import Pakila.Core.Machine
import Pakila.Core.State
import Pakila.Protocol.Types

open Lyceum
open Pakila
open Pakila.Protocol

--TEMP_MARKER--

namespace Pakila.Governance.PolicyEngine

/-- 
ポリシーファイル（TOML/JSON）のロードと検証を行う。
ここでは簡易的に、ホワイトリスト/ブラックリスト形式のポリシーを定義。
-/
def enforcePolicies (s : InterpreterState) (action : MachineAction) : Except AppError Unit := Id.run do
  let rec check (policies : List String) : Except AppError Unit :=
    match policies with
    | [] => .ok ()
    | p :: rest =>
        match p.splitOn ":" with
        | ["readonly", scope] =>
            match action with
            | .WriteFile path .. =>
                let scopeBase := scope.replace "*" ""
                if path.startsWith scopeBase then
                   Except.error (AppError.ExecutionError s!"Policy Violation: {path} is in readonly scope {scope}.")
                else check rest
            | _ => check rest
        | ["deny", tool] =>
            match action with
            | .ExecuteBash _ => if tool == "execute_bash" || tool == "run_shell_command" then Except.error (.ExecutionError s!"Policy Violation: {tool} is denied.") else check rest
            | _ => check rest
        | _ => check rest
  check s.policies

end Pakila.Governance.PolicyEngine
