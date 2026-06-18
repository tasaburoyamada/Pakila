import Pakila.Protocol.Types

namespace Pakila.Test

/-- 監査対象となる機能ID -/
inductive FeatureId where
  | ST01_ClearScreen
  | IN01_PromptDisplay
  | RN02_BoldStyle
  | RN03_CodeBlock
  | EX01_ThinkingSpinner
  | EV02_SessionSave
deriving Repr, BEq

/-- 機能とプロトコルアクションの契約定義 -/
structure FunctionalContract where
  id : FeatureId
  action : Pakila.Protocol.MachineAction
  expectedOutputPattern : String

/-- 網羅リスト -/
def functionalCoverage : List FunctionalContract := [
  { id := .ST01_ClearScreen, action := .Governance .AuditIntegrity, expectedOutputPattern := "" },
  { id := .IN01_PromptDisplay, action := .CallLlm [], expectedOutputPattern := "❯" },
  { id := .RN02_BoldStyle, action := .CallLlm [], expectedOutputPattern := "\x1b[1m" },
  { id := .RN03_CodeBlock, action := .CallLlm [], expectedOutputPattern := "\x1b[38;5;236m" },
  { id := .EX01_ThinkingSpinner, action := .CallLlm [], expectedOutputPattern := "Thinking..." },
  { id := .EV02_SessionSave, action := .Governance .AuditIntegrity, expectedOutputPattern := "SessionSaved" }
]

end Pakila.Test
