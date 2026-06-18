import Pakila.Core.Primitives -- For AppConfig, LlmManager (opaque types)
import Pakila.Core.LlmManager -- For LlmInstance'
import Pakila.Core.Types -- For SessionStatus, ExecutionMode
import Pakila.Governance.Vlog -- For VlogNode
import Pakila.Memory.VectorDB -- For VectorDB
import Pakila.Plugins.Sandbox -- For IsolationLevel
import Pakila.Memory.NativeEmbedding -- For NativeEmbeddingModel

open Lyceum
open Pakila.Protocol
open Pakila.Memory

namespace Pakila

/-- Interpreter の現在の状態 -/
structure InterpreterState where
  history : List Message
  vlogState : List VlogNode
  vectorDb : VectorDB := ∅
  summary : Option Message := none
  turnCount : Nat := 0
  status : SessionStatus := .inProgress
  sessionId : String := "current"
  currentTopic : Option String := none
  policies : List String := []
  worktree : Option String := none
  skipTrust : Bool := false
  sandbox : Bool := false
  sandboxLevel : IsolationLevel := .Low
  embeddingModel : Option NativeEmbeddingModel := none
  interactive : Bool := true
  executionMode : ExecutionMode := .Interactive
  configDir : System.FilePath := "."
  selfHealingCount : Nat := 0
  activeLlm : LlmInstance'
  activeModelName : String
deriving Inhabited


/-- 実行結果を受け取り、次のループへ遷移する継続インターフェース -/
structure Continuation (m : Type → Type) where
  runLoop : InterpreterState → m Unit
  stepAction : Pakila.Protocol.MachineAction → InterpreterState → m Unit
end Pakila
