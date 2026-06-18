import LeanTensor.Math.Tensor
import LeanTensor.Math.Shape
import LeanTensor.Math.Ops
import Lyceum.Types
import Pakila.Core.Interface

namespace Pakila.Memory.Raw

open LeanTensor

/-- 実行時に読み込まれる未検証テンソル -/
structure RawTensor where
  dims : List Nat
  data : Array Float
deriving Inhabited, Repr

/-- Gemma用 Transformer 層 (未検証) -/
structure RawGemmaLayer where
  attn_q : RawTensor
  attn_k : RawTensor
  attn_v : RawTensor
  attn_o : RawTensor
  ffn_gate : RawTensor
  ffn_up : RawTensor
  ffn_down : RawTensor
  attn_norm : RawTensor
  post_attn_norm : RawTensor
  ffn_norm : RawTensor
  post_ffw_norm : RawTensor
deriving Inhabited, Repr

/-- Gemma モデル (未検証) -/
structure RawGemmaModel where
  token_embd : RawTensor
  layers : Array RawGemmaLayer
  norm_final : RawTensor
deriving Inhabited, Repr

/-- 
動的テンソルを検証し、コンパイル時に確定している Tensor 型へ昇格させる。
Lean 4 の依存型を構築するために、実行時の次元比較結果を証明として利用する。
-/
def promoteToVerified (t : RawTensor) (dims : List Nat) : Except String (Tensor dims) :=
  let t_dims := t.dims
  let t_data := t.data
  if h : t_dims = dims then
    let size := Shape.prod t_dims
    let expected_size := Shape.prod dims
    if h_size : t_data.size = size then
      Except.ok { val := t_data, prop := by rw [h_size]; simp [size, expected_size, h] }
    else
      Except.error s!"Data size mismatch: got {t_data.size}, expected {expected_size}"
  else
    Except.error s!"Dimension mismatch: got {t_dims}, expected {dims}"

end Pakila.Memory.Raw
