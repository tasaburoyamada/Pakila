import Pakila.Util.String
import Pakila.Core.Interface
import Pakila.Core.Environment
import Lyceum.Types
import Lyceum.Inference

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

/-- モデルのロード状態 -/
inductive LoadStatus where
  | unloaded
  | loaded (addr : UInt64) -- メモリ上のベースアドレス
deriving Repr, Inhabited, BEq

/-- モデルの管理ハンドル -/
structure ModelHandle where
  modelName : String
  path : String
  status : LoadStatus
  lastUsed : Nat 
deriving Repr, Inhabited

/-- リソース管理状態 -/
structure ResourceManager where
  activeModels : List ModelHandle := []
  maxMemory : UInt64 := 4 * 1024 * 1024 * 1024
  currentUsage : UInt64 := 0
deriving Repr, Inhabited

/-- 物理ロードのFFI定義 -/
@[extern "lean_load_model_native"]
opaque loadModelNative (path : @& String) : IO UInt64

/-- 物理アンロードのFFI定義 -/
@[extern "lean_unload_model_native"]
opaque unloadModelNative (addr : UInt64) : IO Unit

/-- モデルをロードする -/
def ResourceManager.loadModel (self : ResourceManager) (name : String) (path : String) : IO (Except AppError ResourceManager) := do
  TerminalEnv.println s!"[ResourceManager] Physically loading model: {name} from {path}..."
  try
    let addr ← loadModelNative path
    let newHandle : ModelHandle := { modelName := name, path := path, status := .loaded addr, lastUsed := 0 }
    return Except.ok { self with activeModels := newHandle :: self.activeModels }
  catch e =>
    return Except.error (AppError.IoError s!"Failed to load model {name}: {repr e}")

/-- モデルをアンロードする -/
def ResourceManager.unloadModel (self : ResourceManager) (name : String) : IO (Except AppError ResourceManager) := do
  TerminalEnv.println s!"[ResourceManager] Physically unloading model: {name}..."
  match self.activeModels.find? (·.modelName == name) with
  | some h =>
      match h.status with
      | .loaded addr => 
          unloadModelNative addr
          let newModels := self.activeModels.filter (fun h => h.modelName != name)
          return Except.ok { self with activeModels := newModels }
      | .unloaded => return Except.ok self
  | none => return Except.error (AppError.ConfigError s!"Model {name} not found.")

end Pakila
