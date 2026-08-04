import Pakila.Core.State
import Pakila.Core.Machine
import Nomos.Contract
import Nomos.Laws

namespace Pakila.Verification

open Nomos

/-- Pakila の遷移関数を Nomos の Agent インターフェースに適合させる -/
def pakilaAgent : Agent InterpreterState String MachineAction := {
  initialState := Inhabited.default
  step := transition
}

/-- 
安全性不変則 (Invariant): 
セッション ID は遷移プロセスを通じて不変でなければならない。
-/
def SessionIdInvariance (s : InterpreterState) : Prop :=
  s.sessionId == "current" -- 初期値が "current" であることを前提

/-- 
Pakila が Nomos の検証済みエージェント（VerifiedAgent）であることを証明する 
-/
instance : VerifiedAgent InterpreterState String MachineAction where
  agent := pakilaAgent
  safeState := fun s => s.sessionId = "current"
  
  -- 初期状態の安全性を証明
  initialSafe := by
    simp [pakilaAgent, Inhabited.default]
    rfl

  -- 各ステップが安全性を維持することを証明
  stepSafe := by
    intro s o h
    simp [pakilaAgent, transition]
    split
    · -- startsWith "/"
      split
      · -- /model
        exact h
      · -- /auth
        exact h
      · -- /help
        exact h
      · -- /reset
        simp [h]
      · -- /clear
        exact h
      · -- /exit
        exact h
      · -- /quit
        exact h
      · -- others
        simp [h]
    · -- normal input
      simp [h]

end Pakila.Verification
