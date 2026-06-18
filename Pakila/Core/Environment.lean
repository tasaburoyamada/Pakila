import Lean
import Init.System.IO
import Init.System.FilePath
import Pakila.Plugins.FFI
import Pakila.Core.Interface

open Pakila.Plugins
open Pakila.Plugins.FFI

namespace Pakila

/-- 物理ターミナルの状態を保持するグローバルRef -/
initialize rawModeRef : IO.Ref Bool ← IO.mkRef false

/-- 物理RAWモード設定のFFI定義 -/
@[extern "lean_enable_raw_mode"]
opaque enableRawModeNative (dummy : Unit) : IO Bool

@[extern "lean_disable_raw_mode"]
opaque disableRawModeNative (dummy : Unit) : IO Unit

@[extern "lean_get_char"]
opaque getCharNative (dummy : Unit) : IO UInt8

@[extern "lean_get_terminal_size"]
opaque getTerminalSizeNative (dummy : Unit) : IO (Nat × Nat)

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

  readChar := getCharNative ()

  enableRawMode := do
    if ← rawModeRef.get then return .ok false
    try
      let success ← enableRawModeNative ()
      if success then 
        rawModeRef.set true
        return .ok true
      else
        return .ok false
    catch e =>
      return .error (s!"RAW mode engage failed: {e}")

  disableRawMode := do
    if ! (← rawModeRef.get) then return
    try
      disableRawModeNative ()
      rawModeRef.set false
    catch _ =>
      pure ()
  
  isRawMode := rawModeRef.get
    
  spawnBrowser url := do
    let term ← IO.getEnv "TERM"
    let dir ← IO.currentDir
    let cmd := if term == some "xterm-256color" || dir.toString.contains "/" then "xdg-open" else "open"
    try
      let _ ← Plugins.FFI.executeWithTimeout cmd #[url] 10
      return true
    catch _ => 
      IO.println s!"[Environment] Browser failed. Please open manually: {url}"
      return false

  getTerminalSize := getTerminalSizeNative ()

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

end Pakila
