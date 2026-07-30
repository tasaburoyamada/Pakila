import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.Prompts
import Pakila.CLI.Theme
import Pakila.CLI.Renderer
import Pakila.Core.ContextLoader
import Pakila.Core.Environment

open Lyceum
open Pakila.CLI.Prompts
open Pakila

--TEMP_MARKER--

namespace Pakila.CLI.MemoryUI

/-- メモリ管理の対話的インターフェース -/
partial def runMemoryManager (workspaceRoot : System.FilePath) (configDir : System.FilePath) : IO Unit := do
  let currentDir ← IO.currentDir
  let ctx ← resolveFullContext workspaceRoot currentDir configDir
  
  TerminalEnv.println "--- Pakila Memory Manager ---"
  TerminalEnv.println "Current Context Sources:"
  if !ctx.globalCtx.isEmpty then TerminalEnv.println s!"  [G] Global: {configDir}/GEMINI.md"
  if !ctx.workspaceCtx.isEmpty then TerminalEnv.println "  [W] Workspace: ./GEMINI.md"
  for (path, _) in ctx.scopedCtxs do
    TerminalEnv.println s!"  [S] Scoped: {path}/GEMINI.md"
  if !ctx.memoryCtx.isEmpty then TerminalEnv.println "  [M] Private: MEMORY.md"
  
  let choice ← selectOption "Memory Action:" ["Exit", "View Content", "Edit (Placeholder)", "Sync All"]
  match choice with
  | some 0 | none => return ()
  | some 1 => 
      TerminalEnv.println "Select source to view:"
      let sources := ["Global", "Workspace"] ++ ctx.scopedCtxs.map (fun (p, _) => s!"Scoped ({p})") ++ ["Private"]
      let sIdx ← selectOption "Source:" sources
      let (termCols, _) ← TerminalEnv.getTerminalSize
      match sIdx with
      | some 0 => TerminalEnv.println (renderCardBox "Global Context" ctx.globalCtx (termWidth := termCols))
      | some 1 => TerminalEnv.println (renderCardBox "Workspace Context" ctx.workspaceCtx (termWidth := termCols))
      | some i => 
          if i >= 2 && i - 2 < ctx.scopedCtxs.length then
            let (path, content) := ctx.scopedCtxs[i - 2]!
            TerminalEnv.println (renderCardBox s!"Scoped Context ({path})" content (termWidth := termCols))
          else
            TerminalEnv.println (renderCardBox "Private Memory" ctx.memoryCtx (termWidth := termCols))
      | none => pure ()
      runMemoryManager workspaceRoot configDir
  | _ => runMemoryManager workspaceRoot configDir

end Pakila.CLI.MemoryUI
