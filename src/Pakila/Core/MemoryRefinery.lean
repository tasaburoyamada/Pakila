import Pakila.Core.Interface
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.Plugins.FFI

open Lyceum
open Pakila

namespace Pakila.Core.MemoryRefinery

/-- 
4ティア・メモリ・プロトコルに従い、関連する全ての記憶ファイルを収集する (最適化版)。
1. Global (~/.gemini/GEMINI.md)
2. Project (./GEMINI.md)
3. Subdirectory (e.g. ./src/GEMINI.md)
4. Private (.pakila/memory/MEMORY.md)
中間文字列連結を単一バッファリング配列にまとめ、パス階層探索を非反復に最適化。
-/
def resolveTieredMemory (workspaceRoot : System.FilePath) (currentDir : System.FilePath) : IO String := do
  let home ← Pakila.Plugins.FFI.getHomeDirectoryNative ()
  let globalPath := System.FilePath.mk home / ".gemini" / "GEMINI.md"
  let projectPath := workspaceRoot / "GEMINI.md"
  let privatePath := workspaceRoot / ".pakila" / "memory" / "MEMORY.md"
  
  -- サブディレクトリの GEMINI.md を非反復探索
  let mut subDirPaths : List System.FilePath := []
  let mut curr := currentDir
  while curr != workspaceRoot && curr.toString != "." && curr.toString != "/" do
    let path := curr / "GEMINI.md"
    if ← path.pathExists then
      subDirPaths := path :: subDirPaths
    match curr.parent with
    | some parent => curr := parent
    | none => break

  let mut sections : Array String := #[]

  let appendSection (label : String) (p : System.FilePath) : IO Unit := do
    if ← p.pathExists then
      let content ← TerminalEnv.readFile p
      sections := sections.push s!"\n--- {label} ({p}) ---\n{content}\n"

  appendSection "Global Memory" globalPath
  appendSection "Project Instructions" projectPath
  for p in subDirPaths.reverse do
    appendSection "Subdirectory Instructions" p
  appendSection "Private Project Memory" privatePath

  return String.join sections.toList

end Pakila.Core.MemoryRefinery
