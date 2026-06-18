import Pakila.Gguf.Parser
import Pakila.Tokenizer.Vocab
import Pakila.Tokenizer.Unigram
import Pakila.Tokenizer.Normalizer

import Pakila.Core.Environment

open Pakila
open Pakila.Gguf
open Pakila.Tokenizer

def main : IO Unit := do
  let homePath ← getHomeDir
  let modelPath := homePath / "models" / "gemma-4-E4B-it-Q4_K_M.gguf"
  
  if !(← modelPath.pathExists) then
    IO.println s!"Model not found: {modelPath}"
    return

  IO.println s!"Loading model for Tokenizer test: {modelPath}"
  match (← parseGgufMetadata modelPath.toString) with
  | .ok (_, kvs) =>
      let mut vocab := emptyVocab
      
      -- メタデータから語彙をロード
      let tokens := kvs.find? (fun (k, _) => k == "tokenizer.ggml.tokens")
      let scores := kvs.find? (fun (k, _) => k == "tokenizer.ggml.scores")
      let types  := kvs.find? (fun (k, _) => k == "tokenizer.ggml.token_type")
      
      match (tokens, scores, types) with
      | (some (_, .array _ tList), some (_, .array _ sList), some (_, .array _ typeList)) =>
          -- リストではなく配列として効率的に処理
          let n := tList.size
          for i in [0:n] do
            if let (.string t, .float32 s, .int32 ty) := (tList[i]!, sList[i]!, typeList[i]!) then
              let tokenType := match ty with
                | 1 => TokenType.normal
                | 2 => TokenType.unknown
                | 3 => TokenType.control
                | 4 => TokenType.userDefined
                | 6 => TokenType.byte
                | _ => TokenType.undefined
              vocab := vocab.add i t s tokenType
          
          IO.println s!"Vocab loaded: {n} tokens."
          
          -- デバッグ: 最初のいくつかのトークンを表示
          let sampleIds := [0, 1, 2, 3, 4, 100, 200, 1000]
          for sid in sampleIds do
            if let some t := vocab.getToken sid then
              IO.println s!"  Token[{sid}]: '{t}'"
          
          -- テストテキスト
          let testInput := "Hello, Pakila! これは Lean 4 で書かれたトークナイザーのテストです。"
          let normalized := normalize testInput
          IO.println s!"Input: {testInput}"
          IO.println s!"Normalized: {normalized}"
          
          let ids := unigramTokenize vocab normalized
          IO.println s!"Token IDs: {ids}"
          
          let decodedTokens := ids.filterMap vocab.getToken
          IO.println s!"Decoded Tokens: {decodedTokens}"
          
          let reconstructed := denormalize vocab decodedTokens
          IO.println s!"Reconstructed: '{reconstructed}'"
          
          if reconstructed == testInput then
            IO.println "Success: Lossless reconstruction achieved!"
          else
            IO.println "Mismatch detected in reconstruction."
          
      | _ => IO.println "Failed to extract required metadata for tokenizer."
      
  | .error e => IO.println s!"Error: {e}"
