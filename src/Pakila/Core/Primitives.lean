import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Lyceum.Inference.Gemini


open Lyceum
open Lean hiding Message

namespace Pakila

/-- LLMインスタンスの具象表現 (hybrid 関連の残骸を完全に一掃) -/
inductive LlmInstance where
  | remote (c : LlmClient)
  | localEngine (c : LlmClient)
  | mcp (c : LlmClient)
deriving Repr

instance : BEq LlmInstance where
  beq a b := match a, b with
    | .remote _, .remote _ => true
    | .localEngine _, .localEngine _ => true
    | .mcp _, .mcp _ => true
    | _, _ => false

instance : Inhabited LlmInstance where
  default := .remote default


instance : Lyceum.LlmBackend LlmInstance where
  streamChatCompletion client msgs options := match client with
    | .remote c => Lyceum.LlmBackend.streamChatCompletion c msgs options
    | .localEngine c => Lyceum.LlmBackend.streamChatCompletion c msgs options
    | .mcp c => Lyceum.LlmBackend.streamChatCompletion c msgs options
  streamContext client ctx options := match client with
    | .remote c => Lyceum.LlmBackend.streamContext c ctx options
    | .localEngine c => Lyceum.LlmBackend.streamContext c ctx options
    | .mcp c => Lyceum.LlmBackend.streamContext c ctx options
  listModels client := match client with
    | .remote c => Lyceum.LlmBackend.listModels c
    | .localEngine c => Lyceum.LlmBackend.listModels c
    | .mcp c => Lyceum.LlmBackend.listModels c


/-- LLMマネージャの抽象表現 (Primitives層では具象型は定義しない) -/
abbrev LlmManager : Type := Unit


end Pakila
