import Pakila.Core.State
import Pakila.Memory.NativeEmbedding
import Pakila.Memory.VectorDB
import Pakila.MainLoop
import Lyceum.Types

open Pakila
open Pakila.Memory
open Lyceum

def main : IO Unit := do
  IO.println "--- Pakila RAG Integration Test ---"
  
  let modelPath := "test/mock_bert.gguf"
  let sessionId := "test_session_rag"
  let dbPath := s!".pakila/sessions/{sessionId}/vector_db.json"
  
  -- 1. Initialize Native Engine
  IO.println "Step 1: Initializing Native Embedding Engine..."
  let embModel ← match (← initNativeEmbedding modelPath) with
    | Except.ok m => pure (some m)
    | Except.error e => 
        IO.println s!"Failed to init engine: {repr e}"
        return

  -- 2. Setup Initial State
  let initialState : InterpreterState := {
    history := [],
    vlogState := [],
    vectorDb := ∅,
    embeddingModel := embModel,
    sessionId := sessionId
  }
  
  -- 3. Simulate StoreMemory Action
  IO.println "Step 2: Testing StoreMemory..."
  let testText := "Pakila is a formalized autonomous interpreter written in Lean 4."
  
  let storeRes : Except AppError Vector ← match initialState.embeddingModel with
    | some m => EmbeddingModel.embed m testText
    | none => 
        IO.println "Error: No embedding model"
        return

  match storeRes with
  | Except.error e => IO.println s!"Store failed during embedding: {repr e}"
  | Except.ok vec =>
      let newEntry : VectorEntry := { id := "mem_1", text := testText, vector := vec, metadata := Lean.Json.null }
      let nextDb := initialState.vectorDb.insert newEntry
      
      IO.println "Persisting DB to disk..."
      let _ ← IO.FS.createDirAll s!".pakila/sessions/{sessionId}"
      nextDb.save dbPath
      IO.println s!"DB saved to {dbPath}"

      -- 4. Simulate SearchMemory Action
      IO.println "Step 3: Testing SearchMemory..."
      let query := "What language is Pakila written in?"
      
      let searchVecRes ← match initialState.embeddingModel with
        | some m => EmbeddingModel.embed m query
        | none => 
            IO.println "Error: No embedding model"
            return
      
      match searchVecRes with
      | .error e => IO.println s!"Search failed during embedding: {repr e}"
      | .ok queryVec =>
          -- Use threshold 0.0 for mock testing
          let results := nextDb.search queryVec 1 0.0
          if results.isEmpty then

            IO.println "Search failed: No results found."
          else
            let (entry, score) := results[0]!
            IO.println s!"Search success!"
            IO.println s!"[Score: {score}] Result: {entry.text}"
            
            -- 5. Test Persistence (Load)
            IO.println "Step 4: Verifying Persistence (Loading from disk)..."
            let loadedDbRes ← VectorDB.load dbPath
            match loadedDbRes with
            | Except.error e => IO.println s!"Load failed: {e}"
            | Except.ok loadedDb =>
                if loadedDb.entries.size == 1 then
                  IO.println "Persistence verified: Loaded 1 entry correctly."
                else
                  IO.println s!"Persistence failed: Expected 1 entry, got {loadedDb.entries.size}"

  IO.println "--- RAG Integration Test Complete ---"
