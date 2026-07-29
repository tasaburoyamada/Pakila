import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Environment
import Pakila.Config.Loader

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila.Governance.SkillManager

open Lean hiding Message

/-- スキルの定義構造体 -/
structure SkillInfo where
  name : String
  description : String
  path : System.FilePath
  enabled : Bool := true
deriving Repr, Inhabited

/-- スキルが配置されているディレクトリの取得 -/
def getSkillDirectories (configDir : System.FilePath) : IO (List System.FilePath) := do
  let xdgConfigDir ← getPakilaConfigDir
  let projectDir := [System.FilePath.mk ".agents" / "skills"]
  return projectDir ++ [configDir / "skills", xdgConfigDir / "skills"]

/-- SKILL.md から説明文を抽出する簡易パーサー -/
def extractDescription (content : String) : String :=
  let lines := content.splitOn "\n"
  let descLine := lines.find? (fun l => l.startsWith "Description:" || l.startsWith "description:")
  match descLine with
  | some l => (l.drop 12).trimAscii.toString
  | none => "No description available."

/-- スキルの一覧取得 -/
def listDiscoveredSkills (configDir : System.FilePath) : IO (List SkillInfo) := do
  let dirs ← getSkillDirectories configDir
  let mut skills := []
  for dir in dirs do
    if ← dir.pathExists then
      let entries ← dir.readDir
      for entry in entries do
        if ← entry.path.isDir then
          let skillMd := entry.path / "SKILL.md"
          if ← skillMd.pathExists then
            let content ← TerminalEnv.readFile skillMd
            let info : SkillInfo := {
              name := entry.fileName,
              description := extractDescription content,
              path := skillMd,
              enabled := true 
            }
            skills := info :: skills
  return skills

/-- スキルをロードし、その内容（指示）を取得する -/
def loadSkill (configDir : System.FilePath) (name : String) : IO (Except AppError String) := do
  let skills ← listDiscoveredSkills configDir
  match skills.find? (·.name == name) with
  | some s => 
      try
        let content ← TerminalEnv.readFile s.path
        return Except.ok content
      catch e =>
        return Except.error (AppError.IoError s!"Failed to read skill file {s.path}: {e}")
  | none => return Except.error (AppError.ToolError s!"Skill '{name}' not found.")

end Pakila.Governance.SkillManager
