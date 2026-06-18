import LeanTensor.Math.Tensor
import LeanTensor.Math.Ops
import LeanTensor.Math.NN
import LeanTensor.Math.Gguf.Reader
import LeanTensor.Math.Gguf.Types
import Lyceum.Types

open LeanTensor
open Lib.Gguf
open Lib.NN
open Lyceum

namespace Pakila.Memory

/-- ゼロ除算防止用の微小値 -/
def eps : Float := 1.0 / 1000000000000.0

/--
ベクトル表現。
Floatの配列として定義する。
-/
structure Vector where
  data : Array Float
deriving Repr, Inhabited, BEq, Lean.ToJson, Lean.FromJson

/-- Gemma用 Transformer 層 -/
structure GemmaLayer where
  attn_q : Tensor [3072, 3072]
  attn_k : Tensor [3072, 3072]
  attn_v : Tensor [3072, 3072]
  attn_o : Tensor [3072, 3072]
  ffn_gate : Tensor [3072, 3072]
  ffn_up : Tensor [3072, 3072]
  ffn_down : Tensor [3072, 3072]
  attn_norm : Tensor [3072]
  post_attn_norm : Tensor [3072]
  ffn_norm : Tensor [3072]
  post_ffw_norm : Tensor [3072]
deriving Inhabited

/-- 検証済みGemmaモデル -/
structure VerifiedGemmaModel where
  token_embd : Tensor [3815, 3072]
  layers : Array VerifiedGemmaLayer
  norm_final : Tensor [3072]
deriving Inhabited

/-- Token ID から埋め込みベクトルを取得 -/
def embeddingLookup (embd_weight : Tensor [3815, 3072]) (token_ids : List Nat) : Tensor [token_ids.length, 3072] :=
  let seq_len := token_ids.length
  let data := Array.ofFn (n := seq_len * 3072) (fun idx =>
    let row := idx.val / 3072
    let col := idx.val % 3072
    if h : row < token_ids.length then
      let id := token_ids[row]!
      if h_emb : id * 3072 + col < embd_weight.val.size then
        embd_weight.val[id * 3072 + col]
      else 0.0
    else 0.0
  )
  { val := data, prop := by rw [Array.size_ofFn]; simp [Shape.prod, seq_len] }

/-- LayerNorm Implementation -/
def layerNorm {batch seq_len dim : Nat} (x : Tensor [batch * seq_len, dim]) : Tensor [batch * seq_len, dim] :=
  let res := Array.ofFn (n := batch * seq_len * dim) (fun idx =>
    let row := idx.val / dim
    let rec calc_sum (k : Nat) (acc : Float) : Float :=
      if h : k < dim then
        let v := if hv : row * dim + k < x.val.size then x.val[row * dim + k] else 0.0
        calc_sum (k + 1) (acc + v)
      else acc
    let mean := calc_sum 0 0.0 / dim.toFloat
    
    let rec calc_var (k : Nat) (acc : Float) : Float :=
      if h : k < dim then
        let v := if hv : row * dim + k < x.val.size then x.val[row * dim + k] else 0.0
        let diff := v - mean
        calc_var (k + 1) (acc + diff * diff)
      else acc
    let std := Float.sqrt (calc_var 0 0.0 / dim.toFloat + eps)
    
    if h : idx.val < x.val.size then
      (x.val[idx.val] - mean) / std
    else 0.0
  )
  have h_res : res.size = Shape.prod [batch * seq_len, dim] := by
    rw [Array.size_ofFn]
    simp [Shape.prod]
  { val := res, prop := h_res }

end Pakila.Memory
