import LeanTensor.Math.Gguf.Parser
import LeanTensor.Math.Gguf.Reader
import LeanTensor.Math.Gguf.Types
import LeanTensor.Math.Ops
import LeanTensor.Math.Tensor
import Lyceum.Inference
import Lyceum.Types
import Pakila.Memory.Native
import Pakila.Memory.Raw
import Pakila.Tokenizer.Unigram
import Pakila.Tokenizer.Vocab
import Pakila.Core.Environment
import Pakila.Memory.ModelLoader
import Pakila.Memory.Embedding
import Pakila.Core.Config

open Lyceum
open Pakila.Memory
open Pakila.Memory.Raw
open Pakila.Core

namespace Pakila

/-- 物理的なトークナイザー実装 -/
structure Tokenizer where
  modelName : String
  vocab : Pakila.Tokenizer.Vocab
deriving Inhabited, Repr

/-- テンプレートの種類 -/
inductive ChatTemplate where
  | alpaca
  | chatml
  | gemma
deriving Inhabited, Repr

structure LocalLeanTensorLlm where
  modelPath : String
  mmprojPath : Option String := none
  tokenizerInstance : Pakila.Tokenizer
  template : ChatTemplate := .alpaca
  gemmaModel : Option RawGemmaModel := none
deriving Inhabited

instance : Repr LocalLeanTensorLlm where
  reprPrec self _ := s!"LocalLeanTensorLlm(modelPath: {self.modelPath})"

/-- 履歴からプロンプトを生成 -/
def historyToPrompt (_template : ChatTemplate) (history : List Message) : String :=
  history.map (fun msg => s!"{msg.content}\n") 
    |>.foldl (· ++ ·) ""

instance : LlmBackend LocalLeanTensorLlm where
  listModels _ := pure (Except.ok ["local-leantensor-gemma-4b"])

  streamChatCompletion self history _ := do
    let prompt := historyToPrompt self.template history

    -- 1. 物理モデルのロード
    let modelRaw ← match ← loadRawGemmaModel self.modelPath with
          | .ok m => pure m
          | .error e => return .error e

    -- 2. トークン化
    let tokenIds := Pakila.Tokenizer.unigramTokenize self.tokenizerInstance.vocab prompt

    -- 3. 検証と昇格 (本物モデルのパラメータを使用: Hidden=2560, Vocab=3815)
    let token_embd ← match promoteToVerified modelRaw.token_embd [2560, 3815] with 
        | .ok t => pure t 
        | .error e => return .error (AppError.ExecutionError e)
    let input_vec := embeddingLookup token_embd tokenIds

    -- 4. 推論ループ (検証済みの構造体を使用: Hidden=2560)
    let layerRaw := modelRaw.layers[0]!
    let attn_q ← match promoteToVerified layerRaw.attn_q [2560, 2560] with 
        | .ok t => pure t 
        | .error e => return .error (AppError.ExecutionError e)
    
    let output := LeanTensor.matmul input_vec attn_q

    return Except.ok [Message.mkText .assistant s!"[Physical Inference] Output norm: {output.val[0]!}"]

  streamContext _self _ctx _start _len := do
    return Except.error (AppError.LlmError "Not implemented")

end Pakila
