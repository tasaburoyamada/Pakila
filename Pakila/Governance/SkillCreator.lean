import Lyceum.Types
import Lyceum.Inference
import Pakila.Governance.SkillManager
import Pakila.Core.Environment

open Lyceum

--TEMP_MARKER--

namespace Pakila.Governance.SkillCreator

/-- 
新しいスキルを生成し、システムに登録する。
AI が自らツールを拡張するための核心機能。
-/
def createNewSkill (configDir : System.FilePath) (name : String) (description : String) (code : String) : IO (Except AppError Unit) := do
  let skillDir := configDir / "skills" / name
  if !(← skillDir.pathExists) then
    TerminalEnv.createDirAll skillDir
  
  let skillFile := skillDir / "SKILL.md"
  if ← skillFile.pathExists then
    return Except.error (AppError.ExecutionError s!"Skill {name} already exists at {skillFile}")
  
  let content := s!"# Skill: {name}\n\n{description}\n\n## Implementation\n\n```bash\n{code}\n```"
  TerminalEnv.writeFile skillFile content
  
  return Except.ok ()

end Pakila.Governance.SkillCreator
