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

  readChar := do
    let stdin ← IO.getStdin
    let buf ← stdin.read 1
    if buf.isEmpty then return 0
    return buf[0]!

  enableRawMode := do
    try
      let ok ← enableRawModeNative ()
      if ok then return .ok true else return .error "Failed to enable RAW mode via FFI"
    catch e =>
      return .error s!"Failed to enable RAW mode: {e}"

  disableRawMode := do
    disableRawModeNative ()

  isRawMode := return true

  spawnBrowser url := do
    let term ← IO.getEnv "TERM"
    let dir ← IO.currentDir
    let cmd := if term == some "xterm-256color" || dir.toString.contains "/" then "xdg-open" else "open"
    try
      let _ ← IO.Process.run { cmd := cmd, args := #[url] }
      return true
    catch _ => 
      IO.println s!"[Environment] Browser failed. Please open manually: {url}"
      return false

  getTerminalSize := do
    let colsOpt ← IO.getEnv "COLUMNS"
    let linesOpt ← IO.getEnv "LINES"
    match (colsOpt, linesOpt) with
    | (some c, some l) =>
        let cols := c.toNat?.getD 80
        let lines := l.toNat?.getD 24
        return (cols, lines)
    | _ =>
        try
          getTerminalSizeNative ()
        catch _ =>
          return (80, 24)

  loadHistory path := do
    let historyPath := path / "pakila_history"
    if !(← historyPath.pathExists) then
      return []
    let content ← IO.FS.readFile historyPath
    return content.splitOn "\n" |>.filter (!·.isEmpty)

  appendHistory path line := do
    if line.trimAscii.toString.isEmpty then return
    let historyPath := path / "pakila_history"
    let h ← IO.FS.Handle.mk historyPath .append
    h.putStrLn line
    h.flush

  readFile path := IO.FS.readFile path
  readBinFile path := IO.FS.readBinFile path
  writeFile path content := IO.FS.writeFile path content
  createDirAll path := IO.FS.createDirAll path
  rename old new := IO.FS.rename old new
  removeFile path := IO.FS.removeFile path
  pathExists path := path.pathExists
  writeBinFile path data := IO.FS.writeBinFile path data
  isDir path := path.isDir
  readDir path := do
    let entries ← path.readDir
    return entries.map (fun e => e.path) |>.toList
  getFileName path := pure (path.fileName.getD "")
  spawnProcess args := do
    try
      let child ← IO.Process.spawn args
      return .ok child
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
