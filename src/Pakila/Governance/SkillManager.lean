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

/-- SKILL.md から説明文を抽出する確実なパーサー (動的キー＆クォート対応) -/
def extractDescription (content : String) : String :=
  let lines := content.splitOn "\n"
  let descLine := lines.find? (fun l => 
    let trimmed := l.trimAscii.toString
    trimmed.startsWith "Description:" || trimmed.startsWith "description:"
  )
  match descLine with
  | some l => 
      let parts := l.splitOn ":"
      if parts.length > 1 then
        let rawVal := String.join (parts.tail.map (· ++ ":"))
        let val := rawVal.dropRight 1 |>.trimAscii.toString
        let unquoted := if val.startsWith "\"" && val.endsWith "\"" then (val.drop 1 |>.dropRight 1).trimAscii.toString else val
        if unquoted.isEmpty then "No description available." else unquoted
      else "No description available."
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
