import Pakila.Util.String
import Lean
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Environment

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

open Lean hiding Message

/-- セッション履歴をロードする -/
def loadSessionHistory (path : System.FilePath) : IO (Except AppError (List Message)) := do

  if !(← path.pathExists) then
    return Except.ok []
  
  let content ← TerminalEnv.readFile path
  match Json.parse content with
  | .ok json => 
    match fromJson? (α := List Message) json with
    | .ok history => return Except.ok history
    | .error e => return Except.error (AppError.SerializationError e)
  | .error e => return Except.error (AppError.SerializationError e)

/-- セッション履歴を保存する -/
def saveSessionHistory (path : System.FilePath) (history : List Message) : IO (Except AppError Unit) := do

  let jsonContent := toJson history
  try
    TerminalEnv.writeFile path (jsonContent.pretty)
    return Except.ok ()
  catch e =>
    return Except.error (AppError.IoError (s!"{repr e}"))

end Pakila
