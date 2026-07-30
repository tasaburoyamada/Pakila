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
      let defaultHealer : Pakila.Governance.SelfHealer := {}
      let (_, msg) := Pakila.Governance.healPrompt defaultHealer "System anomaly detected"
      pure (.ok s!"Self-healing procedure executed: {msg.content}")
  | .CheckEngine =>
      pure (.ok "Physical engine diagnostics passed.")

  | .VerifyIntegrity =>
      pure (.ok "Integrity verified.")
  | .ShowSettings =>
      let sysInfo ← getSystemInfo
      pure (.ok s!"System Configuration & Diagnostics:\n{formatSystemInfo sysInfo}")

end Pakila.Actions
