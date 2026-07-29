import Lean.Data.Json
import Pakila.Core.Wasm
import Lyceum.Types

namespace Pakila.Plugins

/-- WASMプラグインのメタデータ -/
structure WasmPlugin where
  name : String
  path : String
  entryPoint : String := "main"
deriving Inhabited, Repr

/-- プラグインディレクトリを走査してロード可能なWASMを見つける -/
def discoverWasmPlugins (dir : System.FilePath) : IO (List WasmPlugin) := do
  if !(← dir.pathExists) then return []
  let mut plugins := []
  for entry in ← dir.readDir do
    let path := entry.path
    if path.extension == some "wasm" then
      let name := path.fileStem.getD "unknown"
      plugins := plugins ++ [{ name := name, path := path.toString }]
  return plugins

/-- 指定されたプラグインを実行する -/
def runWasmPlugin (plugin : WasmPlugin) : IO (Except Lyceum.AppError String) := do
  try
    let res ← Pakila.wasmExecute plugin.path plugin.entryPoint
    return .ok res
  catch e =>
    return .error (.ExecutionError s!"WASM Error: {e}")

end Pakila.Plugins
