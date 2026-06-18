import Pakila.Memory.VectorDB
import Pakila.Tokenizer.WordPiece
import Pakila.Tokenizer.Vocab
import Lyceum.Types

open Pakila.Memory
open Pakila.Tokenizer
open Lyceum

def testVectorDBBoundaries : IO Unit := do
  IO.println "\n[Test] VectorDB Boundaries (0-dim, NaN prevention)"
  let mut db : VectorDB := ∅
  
  -- Test 0-dim vector insertion and search
  let emptyVec : Vector := { data := #[] }
  let entry1 : VectorEntry := { id := "1", text := "empty", vector := emptyVec, metadata := Lean.Json.null }
  db := db.insert entry1
  
  let res := db.search emptyVec 5 0.0
  if res.isEmpty then
    IO.println "✔ VectorDB boundary verified: Empty vector search handled gracefully."
  else
    -- Usually distance with 0-dim is 0, so similarity is 1.0 or NaN
    let score := res[0]!.2
    if score.isNaN then
      IO.println "✖ VectorDB boundary failed: NaN similarity score."
    else
      IO.println s!"✔ VectorDB boundary verified: Score is {score}"

def testTokenizerMultiByte : IO Unit := do
  IO.println "\n[Test] Tokenizer Multi-byte (Japanese)"
  let mut v := emptyVocab
  v := v.add 0 "[UNK]" 0.0 .control
  v := v.add 1 "日本" 0.0 .normal
  v := v.add 2 "##語" 0.0 .normal
  v := v.add 3 "##テスト" 0.0 .normal
  
  let text := "日本語テスト"
  let tokens := wordPieceTokenize v text
  
  if tokens == [1, 2, 3] then
    IO.println "✔ Tokenizer Multi-byte verified: Correctly split Japanese text."
  else
    IO.println s!"✖ Tokenizer Multi-byte failed: {tokens}"

def main : IO Unit := do
  IO.println "--- RAG & Inference Gaps Test ---"
  testVectorDBBoundaries
  testTokenizerMultiByte
  IO.println "--- Test Complete ---"
