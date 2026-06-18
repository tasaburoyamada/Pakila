import Pakila.Core.Interface
import Pakila.Core.Environment
import Lyceum.Types
import Lyceum.Inference

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

structure LoadedContext where
  globalCtx : String := ""
  extensionCtxs : List (String × String) := [] 
  workspaceCtx : String := ""
  scopedCtxs : List (String × String) := [] 
  memoryCtx : String := ""
  memorySiblings : List (String × String) := [] 
deriving Repr, Inhabited

def readFileSafe (path : System.FilePath) : IO String := do
  if (← path.pathExists) then
    try TerminalEnv.readFile path catch _ => pure ""
  else pure ""

/-- 親ディレクトリを遡って GEMINI.md を検索する -/
partial def findScopedInstructions (current : System.FilePath) (root : System.FilePath) : IO (List (String × String)) := do
  let rec loop (dir : System.FilePath) (acc : List (String × String)) : IO (List (String × String)) := do
    let path := dir / "GEMINI.md"
    let content ← readFileSafe path
    let newAcc := if content.isEmpty then acc else (dir.toString, content) :: acc
    if dir.toString == root.toString || dir.toString == "/" || dir.toString == "." then
      return newAcc
    else
      match dir.parent with
      | some p => loop p newAcc
      | none => return newAcc
  loop current []

/-- Gemini 仕様に基づくコンテキスト解決 (Localized for Pakila) -/
def resolveFullContext (workspaceRoot : System.FilePath) (currentDir : System.FilePath) (configDir : System.FilePath) : IO LoadedContext := do
  let globalCtx ← readFileSafe (configDir / "GEMINI.md")
  let workspaceCtx ← readFileSafe (workspaceRoot / "GEMINI.md")
  let scopedCtxs ← findScopedInstructions currentDir workspaceRoot
  
  -- .gemini への依存を排除。configDir 配下の相対パスを使用する。
  let memoryDir := configDir / "memory"
  let memoryCtx ← readFileSafe (memoryDir / "MEMORY.md")
  
  return {
    globalCtx := globalCtx,
    workspaceCtx := workspaceCtx,
    scopedCtxs := scopedCtxs,
    memoryCtx := memoryCtx
  }

/-- 階層化されたコンテキストを整形する -/
def formatFullContext (ctx : LoadedContext) : String :=
  let buildParts (parts : List (String × String)) (acc : String) : String :=
    parts.foldl (fun a (name, c) => a ++ s!"--- {name} ---\n{c}\n") acc

  let baseOutput := "<loaded_context>\n"
  
  let output := if !ctx.globalCtx.isEmpty then
    baseOutput ++ s!"--- Global Context (GEMINI.md) ---\n{ctx.globalCtx}\n"
  else baseOutput
    
  let output := buildParts ctx.extensionCtxs output
  let output := if !ctx.workspaceCtx.isEmpty then
    output ++ s!"--- Workspace Root Context ---\n{ctx.workspaceCtx}\n"
  else output
    
  let output := buildParts ctx.scopedCtxs output
  output ++ "</loaded_context>"

end Pakila
