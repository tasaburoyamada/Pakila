import Lyceum.Inference
import Lyceum.Types
import Pakila.Core.ResourceManager
import Pakila.Plugins.Bash
import Pakila.Plugins.WasmLoader
import Pakila.Plugins.Sandbox

open Lyceum

namespace Pakila

/-- Dispatcherを管理する状態 -/
structure Dispatcher where
  bashEngine : BashEngine
  sandboxEngine : SandboxEngine
  useSandbox : Bool := false
  resManager : ResourceManager
  wasmPlugins : List Plugins.WasmPlugin := []
  taskCounter : Nat := 0
deriving Repr

/-- 新しいタスクのディレクトリを作成し、IDを返す -/
def Dispatcher.createTaskDir (self : Dispatcher) : IO (Nat × System.FilePath) := do
  let id := self.taskCounter
  let path := System.FilePath.mk s!"logs/tasks/{id}"
  let _ ← IO.FS.createDirAll path
  return (id, path)

instance : ExecutionEngine Dispatcher where
  prepare self code lang := 
    if self.useSandbox then
      ExecutionEngine.prepare self.sandboxEngine code lang
    else
      match lang with
      | "bash" => ExecutionEngine.prepare self.bashEngine code lang
      | _ => .error (Lyceum.AppError.ExecutionError "Unsupported language")

/-- ディスパッチャのモデル操作メソッド -/
def Dispatcher.handleAction (self : Dispatcher) (name : String) (path : String) (action : String) : IO Dispatcher := do
  match action with
  | "load" =>
      match (← self.resManager.loadModel name path) with
      | .ok rm => return { self with resManager := rm }
      | .error _ => return self
  | "unload" =>
      match (← self.resManager.unloadModel name) with
      | .ok rm => return { self with resManager := rm }
      | .error _ => return self
  | _ => return self

end Pakila
