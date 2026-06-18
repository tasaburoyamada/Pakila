import Pakila.Util.String
import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.Renderer
import Pakila.Core.Environment

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

/-- セッション履歴をMarkdown形式でファイルに出力する -/
def exportToMarkdown (path : System.FilePath) (history : List Message) : IO (Except AppError Unit) := do
  let header := "# Pakila Session Report\n\n"
  let body := history.map (fun msg => 
    let roleStr := match msg.role with
      | .system => "System"
      | .user => "User"
      | .assistant => "AI"
      | .tool => "Tool"
    s!"### {roleStr}\n\n{renderMarkdown msg.content}\n\n"
  ) |> String.join
  
  try
    TerminalEnv.writeFile path (header ++ body)
    return Except.ok ()
  catch e =>
    return Except.error (AppError.IoError (s!"{repr e}"))

end Pakila
