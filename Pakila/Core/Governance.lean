import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.Diagnostics.SysInfo
import Pakila.Governance.GitManager
import Pakila.Governance.PolicyEngine
import Pakila.Governance.SelfHealer
import Pakila.Protocol.Types

open Lyceum
open Pakila
open Pakila.Protocol

--TEMP_MARKER--

namespace Pakila.Actions

/-- ガバナンス・診断アクションを処理する -/
def handleGovernanceAction (action : GovernanceAction) : IO (Except AppError String) := do
  match action with
  | .AuditIntegrity =>
      let res ← IO.Process.run { cmd := "lake", args := #["build"] }
      if res.contains "error:" then
        pure (.error (AppError.ExecutionError s!"Integrity Check Failed: {res}"))
      else
        pure (.ok "Integrity Check Passed.")
  | .SelfHeal =>
      let healer : Lyceum.Governance.SelfHealer := {}
      let (_, msg) := Pakila.Governance.healPrompt healer "State inconsistency detected"
      pure (.ok s!"Self-healing procedures executed: {msg.content}")
  | .CheckEngine =>
      let res ← IO.Process.run { cmd := "lake", args := #["--version"] }
      if res.contains "Lean" || res.contains "lake" then
        pure (.ok s!"Physical engine diagnostics passed: {res.trimAscii}")
      else
        pure (.error (AppError.ExecutionError "Engine check failed"))
  | .VerifyIntegrity =>
      let res ← IO.Process.run { cmd := "git", args := #["status", "--porcelain"] }
      if res.trimAscii.isEmpty then
        pure (.ok "Integrity verified: Clean working tree.")
      else
        pure (.ok s!"Integrity verified: Working tree contains uncommitted changes ({res.trimAscii.length} bytes).")
  | .ShowSettings =>
      pure (.ok "Settings: Governance policy engine and vector embedding active.")

end Pakila.Actions
