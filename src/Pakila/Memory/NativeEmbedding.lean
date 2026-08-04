import Pakila.Memory.Embedding
import Pakila.Memory.ModelLoader
import Pakila.Memory.Native
import Pakila.Memory.Raw
import Pakila.Tokenizer.WordPiece
import Lyceum.Types
import Pakila.Core.Config

namespace Pakila.Memory

open Lyceum
open Pakila.Tokenizer
open Pakila.Memory.Raw
open Pakila.Memory.Native

/--
Gemma用のEmbeddingエンジン。
-/
structure NativeEmbeddingModel where
  model : RawGemmaModel
  vocab : Vocab
deriving Inhabited

/--
ゼロ除算防止付き L2 正規化。
ベクトルの各成分をノルムで割り、単位ベクトルに変換する。
-/
private def l2Normalize (data : Array Float) : Array Float :=
  let fa := FloatArray.mk data
  let n := normNative fa
  if n < eps then data
  else data.map (· / n)

/--
token_embd から指定 tokenID の埋め込み行列行を取り出す。
dims = [vocab_size, hidden_dim] の RawTensor を想定。
-/
private def lookupEmbedding (embd : RawTensor) (tokenId : Nat) : Array Float :=
  -- RawTensor.dims = [vocab_size, hidden_dim]
  let hiddenDim := embd.dims.getD 1 0
  if hiddenDim == 0 then #[]
  else
    let offset := tokenId * hiddenDim
    Array.ofFn (n := hiddenDim) fun i =>
      let idx := offset + i
      if idx < embd.data.size then embd.data[idx]! else 0.0

/--
テキストを WordPiece でトークナイズし、token_embd の平均プーリングで
文レベルの埋め込みベクトルを生成する。最後に L2 正規化を施す。
vocab が空（emptyVocab）の場合は文字コードポイントをトークンIDとして代用する。
-/
def NativeEmbeddingModel.embed_impl
    (self : NativeEmbeddingModel) (text : String) : IO (Except AppError Vector) := do
  let embd := self.model.token_embd
  let hiddenDim := embd.dims.getD 1 0
  if hiddenDim == 0 then
    return .error (.ExecutionError "token_embd hidden_dim is 0: model may not be loaded")

  -- トークナイズ：vocab が空なら UTF-32 コードポイントをそのまま使う
  let tokenIds : List Nat :=
    if self.vocab.tokenToId.isEmpty then
      text.toList.map (fun c => c.toNat % embd.dims.getD 0 1)
    else
      wordPieceTokenize self.vocab text

  if tokenIds.isEmpty then
    -- 空入力はゼロベクトル
    return .ok { data := Array.replicate hiddenDim 0.0 }

  -- 平均プーリング（mean pooling）
  let sumVec : Array Float := tokenIds.foldl
    (fun acc tid =>
      let row := lookupEmbedding embd tid
      Array.ofFn (n := hiddenDim) fun i =>
        let a := if i < acc.size then acc[i]! else 0.0
        let b := if i < row.size then row[i]! else 0.0
        a + b)
    (Array.replicate hiddenDim 0.0)

  let n := tokenIds.length.toFloat
  let meanVec := sumVec.map (· / n)

  -- L2 正規化
  let normalized := l2Normalize meanVec
  return .ok { data := normalized }

/--
初期化関数：GGUFからロードしてエンジンを構築する。
-/
def initNativeEmbedding (path : String) : IO (Except AppError NativeEmbeddingModel) := do
  match ← loadRawGemmaModel path with
  | .ok m =>
      return .ok { model := m, vocab := emptyVocab }
  | .error e => return .error e

end Pakila.Memory
