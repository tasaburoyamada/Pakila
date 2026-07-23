import Lean
import Init.System.IO
import Init.System.FilePath
import Pakila.Plugins.FFI
import Pakila.Core.Interface
import Pakila.CLI.Theme

open Pakila.Plugins
open Pakila.Plugins.FFI
open Pakila

namespace Pakila.CLI.TerminalIO -- 新しいモジュール名

/-- 実機 (IOモナド) 用の物理環境実装 -/
instance : TerminalEnv IO where
  print s := do 
    IO.print s
    (← IO.getStdout).flush
  
  println s := do
    IO.println s
    (← IO.getStdout).flush
  
  readLine := do
    let line ← (← IO.getStdin).getLine
    return line.trimAscii.toString

  readChar := IO.println "[System]: readChar is not supported in this simplified IO mode." *> return 0 -- NOP実装

  enableRawMode := IO.println "[System]: RAW mode is not supported in this simplified IO mode." *> return .error "RAW mode is not supported."

  disableRawMode := IO.println "[System]: RAW mode is not supported in this simplified IO mode." *> pure ()
  
  isRawMode := return false
    
  spawnBrowser url := do
    let term ← IO.getEnv "TERM"
    let dir ← IO.currentDir
    let cmd := if term == some "xterm-256color" || dir.toString.contains "/" then "xdg-open" else "open"
    try
      -- NOTE: タイムアウト機能は一旦削除。必要であれば別途実装。
      let _ ← IO.Process.run { cmd := cmd, args := #[url] }
      return true
      -- IO.Process.run は例外を投げるため、catch でエラーを捕捉
    catch _ -> 
      IO.println s!"[Environment] Browser failed. Please open manually: {url}"
      return false

  getTerminalSize := do IO.println "[System]: getTerminalSize not supported."; return (80, 24) -- ダミー値

  loadHistory path := do
    let historyPath := path / "pakila_history"
    if !(← historyPath.pathExists) then
      return []
    let content ← IO.FS.readFile historyPath
    return content.splitOn "
" |>.filter (!·.isEmpty)

  appendHistory path line := do
    if line.trimAscii.toString.isEmpty then return
    let historyPath := path / "pakila_history"
    let h ← IO.FS.Handle.mk historyPath .append
    h.putStrLn line
    h.flush

  readFile path := IO.FS.readFile path
  readBinFile path := IO.FS.readBinFile path
  writeFile path content := IO.FS.writeFile path content
  createDirAll path := IO.FS.createAll path
  rename old new := IO.FS.rename old new
  removeFile path := IO.FS.removeFile path
  pathExists path := path.pathExists
  writeBinFile path data := IO.FS.writeBinFile path data
  isDir path := path.isDir
  readDir path := do
    let entries ← path.readDir
    return entries.map (fun e => e.path) |>.toList
  getFileName path := pure (path.fileName.getD "")
  spawnProcess args := unsafe do
    try
      let child ← IO.Process.spawn args
      return .ok (unsafeCast child)
    catch e =>
      return .error (s!"Process spawn failed: {e}")
  getEnv var := IO.getEnv var
  getCurrentDir := IO.currentDir
  runProcess args := do
    try
      let out ← IO.Process.run args
      return .ok { exitCode := 0, stdout := out, stderr := "" }
    catch e =>
      return .error (s!"Process run failed: {e}")
  
  renderUserTurn s := do
    let prompt := Pakila.applyColor .cyan "User > "
    IO.print (prompt ++ s)
    (← IO.getStdout).flush

end Pakila.CLI.TerminalIO
