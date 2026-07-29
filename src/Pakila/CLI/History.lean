import Lean
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Environment

open Lyceum

--TEMP_MARKER--

namespace Pakila.CLI.History

open Lean hiding Message

/-- 履歴保存先のパスを取得 (<configDir>/pakila_history) -/
def getHistoryPath (configDir : System.FilePath) : System.FilePath :=
  configDir / "pakila_history"

/-- 履歴の読み込み (汎用版) -/
def loadHistory {m : Type → Type} [Monad m] [TerminalEnv m] (configDir : System.FilePath) : m (List String) :=
  TerminalEnv.loadHistory configDir

/-- 履歴への追記 (汎用版) -/
def appendHistory {m : Type → Type} [Monad m] [TerminalEnv m] (configDir : System.FilePath) (line : String) : m Unit :=
  TerminalEnv.appendHistory configDir line

end Pakila.CLI.History
