import Pakila.Memory.NativeEmbedding
import Lyceum.Types

open Pakila.Memory
open Lyceum

def main : IO Unit := do
  IO.println "--- Testing Pure LeanTensor Embedding Engine with Tokenizer ---"
  
  let modelPath := "test/mock_bert.gguf"
  
  -- 1. Initialize
  IO.println s!"Loading mock model from {modelPath}..."
  match (← initNativeEmbedding modelPath) with
  | .error e => 
      IO.println s!"Failed to initialize: {repr e}"
      return
  | .ok engine =>
      IO.println "Successfully initialized Native Embedding Engine with Vocab."
      
      -- 2. Vocab Check
      IO.println s!"Vocab size: {engine.vocab.tokenToId.size}"
      IO.println s!"ID for 'hello': {repr (engine.vocab.getId "hello")}"
      IO.println s!"ID for '##ly': {repr (engine.vocab.getId "##ly")}"
      
      -- 3. Embed
      let text := "hello native"
      IO.println s!"Executing embedding for '{text}'..."
      match (← EmbeddingModel.embed engine text) with
      | .error e => IO.println s!"Embedding failed: {repr e}"
      | .ok vec =>
          IO.println s!"Embedding success! Vector size: {vec.data.size}"
          IO.println s!"First 5 elements: {vec.data.extract 0 5}"

  IO.println "--- Test Complete ---"
