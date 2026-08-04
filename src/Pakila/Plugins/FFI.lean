import Lean

namespace Pakila.Plugins.FFI

@[extern "lean_python_execute"]
opaque executePythonNative (script : String) : IO String

@[extern "lean_curl_execute"]
opaque executeCurlNative (url : String) : IO String

@[extern "lean_spawn_with_timeout"]
opaque executeNativeWithTimeout (cmd : String) (args : Array String) (timeout : UInt32) : IO String

@[extern "lean_unshare_execute"]
opaque executeNativeIsolated (cmd : String) (args : Array String) : IO String

@[extern "lean_get_executable_path"]
opaque getExecutablePathNative (dummy : Unit) : IO String

@[extern "lean_get_home_directory"]
opaque getHomeDirectoryNative (dummy : Unit) : IO String

/-- Python 実行エンジン -/
def executePython (script : String) : IO String := do
  executePythonNative script

/-- Curl 実行エンジン -/
def executeCurl (url : String) : IO String := do
  executeCurlNative url

/-- タイムアウト付きネイティブ実行 -/
def executeWithTimeout (cmd : String) (args : Array String) (timeout : UInt32 := 30) : IO String := do
  executeNativeWithTimeout cmd args timeout

@[extern "lean_enable_raw_mode"]
opaque enableRawModeNative (dummy : Unit) : IO Bool

@[extern "lean_disable_raw_mode"]
opaque disableRawModeNative (dummy : Unit) : IO Unit

@[extern "lean_get_terminal_size"]
opaque getTerminalSizeNative (dummy : Unit) : IO (Nat × Nat)

/-- ネイティブ隔離実行 (bwrap代替) -/
def executeIsolated (cmd : String) (args : Array String) : IO String := do
  executeNativeIsolated cmd args

end Pakila.Plugins.FFI