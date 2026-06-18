import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference

open Lyceum
open Lean hiding Message

namespace Pakila

/-- LLMインスタンスの抽象表現 (Primitives層では具象型は定義しない) -/
abbrev LlmInstance : Type := Unit

/-- LLMマネージャの抽象表現 (Primitives層では具象型は定義しない) -/
abbrev LlmManager : Type := Unit

end Pakila
