import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.History
import Pakila.CLI.Theme
import Pakila.CLI.SlashCommands
--import Pakila.CLI.TerminalBase -- 削除 (TerminalIOに移動)
import Pakila.Core.Environment
import Pakila.Plugins.FFI

import Pakila.CLI.TerminalIO -- TerminalEnv IO インスタンスをインポート

open Lyceum
open Pakila
open Pakila.CLI
-- open Pakila.CLI.TerminalBase -- 削除
open Pakila.CLI.TerminalIO
open Pakila.CLI.History

namespace Pakila

deriving instance Inhabited for IO.FS.DirEntry

/-- カスタムReadLineの実装 (汎用版) -/
def readLineWithHistory {m : Type → Type} [Monad m] [TerminalEnv m] [MonadFinally m] [MonadLiftT IO m] (prompt : String) (configDir : System.FilePath) : m (Option String) := do
  -- 履歴をロード
  let _ ← loadHistory configDir

  -- プロンプトを表示
  TerminalEnv.print prompt

  let line ← TerminalEnv.readLine
  if !line.trimAscii.toString.isEmpty then
    appendHistory configDir line
  return line


