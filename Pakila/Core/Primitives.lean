import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Lyceum.Inference.Gemini
import Lyceum.Inference.Gemma.Backend -- New import

open Lyceum
open Lean hiding Message

namespace Pakila

/-- LLMインスタンスの具象表現 (hybrid 関連の残骸を完全に一掃) -/
inductive LlmInstance where
  | remote (c : LlmClient)
  | localEngine (c : Lyceum.Inference.Gemma.Backend.LocalLeanTensorLlm) -- Updated type
  | mcp (c : LlmClient)
deriving Repr

instance : Inhabited LlmInstance where
  default := .remote default

/-- LLMマネージャの抽象表現 (Primitives層では具象型は定義しない) -/
abbrev LlmManager : Type := Unit

end Pakila
