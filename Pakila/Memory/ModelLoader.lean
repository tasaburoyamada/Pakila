import LeanTensor.Math.Tensor
import LeanTensor.Math.Gguf.Parser
import LeanTensor.Math.Gguf.Reader
import LeanTensor.Math.Gguf.Types
import Pakila.Memory.Embedding
import Pakila.Memory.Raw
import Pakila.Tokenizer.Vocab
import Pakila.Core.Environment
import Pakila.Core.Config

open LeanTensor
open Lib.Gguf
open Pakila.Tokenizer
open Pakila
open Pakila.Core
open Pakila.Memory.Raw

namespace Pakila.Memory

/-- GGUF ヘッダーをパースするヘルパー -/
def parseGgufHeader (buf : ByteArray) (off : Nat) : Option (GgufHeader × Nat) := do
  if buf.size < off + 24 then none
  let magic := String.fromUTF8! (buf.extract off (off + 4))
  let version := bytesToUInt32Le (buf.extract (off + 4) (off + 8))
  let tensorCount := bytesToUInt64Le (buf.extract (off + 8) (off + 16))
  let metadataCount := bytesToUInt64Le (buf.extract (off + 16) (off + 24))
  return ({ magic := magic, version := version, tensorCount := tensorCount, metadataCount := metadataCount }, off + 24)

/-- メタデータから語彙を抽出する -/
def extractVocab (kvs : List (String × MetadataValue)) : Vocab := Id.run do
  let mut v := emptyVocab
  let tokens := kvs.find? (fun (k, _) => k == "tokenizer.ggml.tokens")
  match tokens with
  | some (_, .array _ elements) =>
    for i in [0:elements.size] do
      match elements[i]! with
      | .string s => v := v.add i s 0.0 .normal
      | _ => pure ()
  | _ => pure ()
  return v

/-- 生データを RawTensor として読み込む -/
def loadRawTensor (tensorInfos : List GgufTensorInfo) (buf : ByteArray) (name : String) : Except Lyceum.AppError RawTensor :=
  match tensorInfos.find? (fun info => info.name == name) with
  | some info =>
      let data := loadGgufTensorData buf info
      .ok { dims := info.dimensions, data := data }
  | none => .error (Lyceum.AppError.ExecutionError s!"Tensor not found: {name}")

/--
GGUFファイルからGemmaモデルの重みをロードする。
-/
def loadRawGemmaModel (path : String) : IO (Except Lyceum.AppError RawGemmaModel) := do
  let (header, _) ← match (← parseGgufMetadata path) with
    | .ok (h, k) => pure (h, k)
    | .error e => return .error (Lyceum.AppError.ExecutionError s!"GGUF Metadata error: {e}")
  
  let buf ← TerminalEnv.readBinFile (System.FilePath.mk path)
  
  let (_, next_off) ← match parseGgufHeader buf 0 with
    | some res => pure res
    | none => return .error (Lyceum.AppError.ExecutionError "Failed to parse GGUF header")

  let mut off := next_off
  for _ in [0:header.metadataCount.toNat] do
    match readGgufString buf off with
    | some (_, off1) =>
        match readBytes buf off1 4 with
        | some (typeBytes, off2) =>
            let type := bytesToUInt32Le typeBytes
            match readMetadataValue buf off2 type with
            | some (_, off3) => off := off3
            | none => break
        | none => break
    | none => break

  let (tensorInfos, _) := parseGgufTensorInfos buf off header.tensorCount.toNat

  -- 1. Load Token Embedding
  let token_embd ← match loadRawTensor tensorInfos buf "token_embd.weight" with
    | .ok t => pure t
    | .error e => return .error e

  -- 2. Load Layers
  let mut layers := #[]
  for i in [0:NUM_LAYERS] do
    let q ← match loadRawTensor tensorInfos buf s!"blk.{i}.attn_q.weight" with | .ok t => pure t | .error e => return .error e
    let k ← match loadRawTensor tensorInfos buf s!"blk.{i}.attn_k.weight" with | .ok t => pure t | .error e => return .error e
    let v ← match loadRawTensor tensorInfos buf s!"blk.{i}.attn_v.weight" with | .ok t => pure t | .error e => return .error e
    let o ← match loadRawTensor tensorInfos buf s!"blk.{i}.attn_output.weight" with | .ok t => pure t | .error e => return .error e
    let gate ← match loadRawTensor tensorInfos buf s!"blk.{i}.ffn_gate.weight" with | .ok t => pure t | .error e => return .error e
    let up ← match loadRawTensor tensorInfos buf s!"blk.{i}.ffn_up.weight" with | .ok t => pure t | .error e => return .error e
    let down ← match loadRawTensor tensorInfos buf s!"blk.{i}.ffn_down.weight" with | .ok t => pure t | .error e => return .error e
    let attn_norm ← match loadRawTensor tensorInfos buf s!"blk.{i}.attn_norm.weight" with | .ok t => pure t | .error e => return .error e
    let post_attn_norm ← match loadRawTensor tensorInfos buf s!"blk.{i}.post_attention_norm.weight" with | .ok t => pure t | .error e => return .error e
    let ffn_norm ← match loadRawTensor tensorInfos buf s!"blk.{i}.ffn_norm.weight" with | .ok t => pure t | .error e => return .error e
    let post_ffw_norm ← match loadRawTensor tensorInfos buf s!"blk.{i}.post_ffw_norm.weight" with | .ok t => pure t | .error e => return .error e
    
    layers := layers.push { 
        attn_q := q, attn_k := k, attn_v := v, attn_o := o, 
        ffn_gate := gate, ffn_up := up, ffn_down := down,
        attn_norm := attn_norm, post_attn_norm := post_attn_norm,
        ffn_norm := ffn_norm, post_ffw_norm := post_ffw_norm
    }

  let norm_final ← match loadRawTensor tensorInfos buf "output_norm.weight" with
    | .ok norm => pure norm
    | .error e => return .error e
  
  return .ok { token_embd := token_embd, layers := layers, norm_final := norm_final }

end Pakila.Memory
