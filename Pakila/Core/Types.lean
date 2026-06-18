import Lean.Data.Json
import Pakila.Core.Interface
import Pakila.Core.Primitives -- AppError, AppConfig, LlmInstance, LlmManager
import Lyceum.Types -- Message needs this
import Lyceum.Inference -- AppError needs this

namespace Pakila

open Lean hiding Message

/-- 実行結果を受け取り、次のループへ遷移する継続インターフェース -/

inductive SessionStatus where
  | inProgress
  | completed
  | awaitingUser
  | failed
deriving Repr, BEq, ToJson, FromJson, Inhabited

inductive ExecutionMode where
  | Interactive
  | Batch
deriving Repr, BEq, Inhabited

end Pakila
