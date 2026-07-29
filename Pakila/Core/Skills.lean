import Pakila.Core.Interface
import Pakila.Protocol.Types
import Pakila.Core.Types
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.Governance.SkillManager
import Pakila.CLI.Theme

open Lyceum
open Pakila
open Pakila.Protocol

namespace Pakila

/-- スキルアクティベーションアクションを処理する -/
def handleActivateSkill (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (name : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ SKILL: Activating '{name}'...\n")
  -- 暫定的に SkillManager.loadSkill が未実装/非互換の場合に備え、直接ファイルを読み込む
  let path := System.FilePath.mk s!"tools/skills/{name}.md"
  try
    let instructions ← TerminalEnv.readFile path
    let content := s!"<activated_skill>\n<name>{name}</name>\n<instructions>\n{instructions}\n</instructions>\n</activated_skill>"
    let toolMsg : Message := { role := .tool, parts := [.toolResponse "activate_skill" content] }
    TerminalEnv.print (applyColor .green s!"✔  Skill '{name}' activated.\n")
    let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
    cont.runLoop finalS
  catch e =>
    TerminalEnv.print (applyColor .red s!"✖  Skill Activation Failed: {e}\n")
    let toolMsg : Message := { role := .tool, parts := [.toolResponse "activate_skill" s!"Error: {e}"] }
    let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
    cont.runLoop finalS

end Pakila
