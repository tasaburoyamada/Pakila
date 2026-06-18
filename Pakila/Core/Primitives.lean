import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Lyceum.Inference.Gemini
import Pakila.Plugins.LocalLeanTensor

open Lyceum
open Lean hiding Message

namespace Pakila

/-- LLMインスタンスの具象表現 -/
inductive LlmInstance where
  | remote (c : LlmClient)
  | localEngine (c : LocalLeanTensorLlm)
  | mcp (c : LlmClient)
  | hybrid (remote : LlmClient) (localEngine : LocalLeanTensorLlm)
deriving Repr

instance : Inhabited LlmInstance where
  default := .remote default

/-- LLMマネージャの抽象表現 (Primitives層では具象型は定義しない) -/
abbrev LlmManager : Type := Unit

end Pakila
