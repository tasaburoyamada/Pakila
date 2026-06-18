import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Lyceum.Inference.Gemini
import Pakila.Plugins.LocalLeanTensor

open Lyceum
open Lean hiding Message

namespace Pakila

/-- LLMインスタンスの具象表現 (hybrid 関連の残骸を完全に一掃) -/
inductive LlmInstance where
  | remote (c : LlmClient)
  | localEngine (c : LocalLeanTensorLlm)
  | mcp (c : LlmClient)
deriving Repr

instance : Inhabited LlmInstance where
  default := .remote default

/-- LLMマネージャの抽象表現 (Primitives層では具象型は定義しない) -/
abbrev LlmManager : Type := Unit

end Pakila
