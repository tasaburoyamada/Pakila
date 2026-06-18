import Pakila.Core.Interface
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.Plugins.FFI

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila.Core.MemoryRefinery

/-- 
4ティア・メモリ・プロトコルに従い、関連する全ての記憶ファイルを収集する。
1. Global (~/.gemini/GEMINI.md)
2. Project (./GEMINI.md)
3. Subdirectory (e.g. ./src/GEMINI.md)
4. Private (.pakila/memory/MEMORY.md)
-/
def resolveTieredMemory (workspaceRoot : System.FilePath) (currentDir : System.FilePath) : IO String := do
  let home ← Pakila.Plugins.FFI.getHomeDirectoryNative ()
  let globalPath := System.FilePath.mk home / ".gemini" / "GEMINI.md"
  let projectPath := workspaceRoot / "GEMINI.md"
  let privatePath := workspaceRoot / ".pakila" / "memory" / "MEMORY.md"
  
  -- サブディレクトリの GEMINI.md を探索 (現在のディレクトリからルートまで遡る)
  let rec findSubDirGemini (dir : System.FilePath) : IO (List System.FilePath) := do
    if dir == workspaceRoot || dir.toString == "." || dir.toString == "/" then return []
    let path := dir / "GEMINI.md"
    let rest ← if let some parent := dir.parent then findSubDirGemini parent else pure []
    if ← path.pathExists then return path :: rest
    else return rest

  let subDirPaths ← findSubDirGemini currentDir
  
  let mut fullContext := ""
  
  let appendFile (label : String) (p : System.FilePath) (acc : String) : IO String := do
    if ← p.pathExists then
      let content ← TerminalEnv.readFile p
      return acc ++ s!"\n--- {label} ({p}) ---\n{content}\n"
    else return acc

  fullContext ← appendFile "Global Memory" globalPath fullContext
  fullContext ← appendFile "Project Instructions" projectPath fullContext
  for p in subDirPaths do
    fullContext ← appendFile "Subdirectory Instructions" p fullContext
  fullContext ← appendFile "Private Project Memory" privatePath fullContext
  
  return fullContext

end Pakila.Core.MemoryRefinery
