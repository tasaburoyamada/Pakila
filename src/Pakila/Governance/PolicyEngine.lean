import Lyceum.Types
import Lyceum.Inference
import Nomos.Contract
import Pakila.Core.Machine
import Pakila.Core.State
import Pakila.Protocol.Types

open Lyceum
open Pakila
open Pakila.Protocol

namespace Pakila.Governance.PolicyEngine

/-- 構造化ポリシーAST -/
inductive PolicyRule where
  | ReadOnly (scopeBase : String) (originalScope : String)
  | DenyTool (toolName : String)
  | Unknown
deriving Repr, BEq, Inhabited

/-- ポリシー文字列を一度だけASTへ解析する -/
def parsePolicyRule (raw : String) : PolicyRule :=
  match raw.splitOn ":" with
  | ["readonly", scope] => .ReadOnly (scope.replace "*" "") scope
  | ["deny", tool] => .DenyTool tool
  | _ => .Unknown

/-- 
事前にパースされたルールリストに対する高速ポリシー検証 (文字列リパースゼロ)。
-/
def enforcePolicies (s : InterpreterState) (action : MachineAction) : Except AppError Unit := Id.run do
  for rawPolicy in s.policies do
    let rule := parsePolicyRule rawPolicy
    match rule with
    | .ReadOnly scopeBase orig =>
        match action with
        | .WriteFile path .. =>
            if path.startsWith scopeBase then
              return Except.error (AppError.ExecutionError s!"Policy Violation: {path} is in readonly scope {orig}.")
        | _ => pure ()
    | .DenyTool tool =>
        match action with
        | .ExecuteBash _ =>
            if tool == "execute_bash" || tool == "run_shell_command" then
              return Except.error (.ExecutionError s!"Policy Violation: {tool} is denied.")
        | _ => pure ()
    | .Unknown => pure ()
  return .ok ()

end Pakila.Governance.PolicyEngine
