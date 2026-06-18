import Lean.Data.Json
import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

namespace Pakila.Test

open Lean hiding Message

def runPhysicalAuthTest : IO UInt32 := do
  IO.println "Running test: Physical Authentication (Environment Loopback)..."
  let port := 18080
  let apiKey := "test-secret-key-456"
  
  -- 1. Start mock server in background
  let _ ← IO.Process.spawn {
    cmd := "python3",
    args := #["test/Util/MockServer.py", toString port]
  }
  
  -- Wait a bit for server to start
  IO.sleep 1000
  
  -- 2. Call LlmClient
  let client : LlmClient := { 
    apiUrl := s!"http://localhost:{port}", 
    apiKey := apiKey,
    modelName := some "models/gemini-2.5-flash"
  }
  
  -- listModels calls the mock server which writes to mock_request.json
  let _ ← LlmBackend.listModels client
  
  -- 3. Verify captured request
  let logFile := "mock_request.json"
  if !(← System.FilePath.mk logFile |>.pathExists) then
    IO.println "  [FAIL] Mock server did not capture any request."
    return 1
    
  let logContent ← IO.FS.readFile logFile
  match Json.parse logContent with
  | .ok j =>
      let path : String := match j.getObjValAs? String "path" with
        | .ok s => s
        | _ => ""
      
      let headers : Json := match j.getObjVal? "headers" with
        | .ok h => h
        | _ => Json.null
      
      let authHeader : String := match headers.getObjValAs? String "x-goog-api-key" with
        | .ok s => s
        | _ => ""
      
      let mut failures := 0
      if !path.contains s!"key={apiKey}" then
        IO.println s!"  [FAIL] Query parameter 'key' missing or incorrect. Path: {path}"
        failures := failures + 1
      else
        IO.println "  [PASS] Query parameter 'key' verified."
        
      if authHeader != apiKey then
        IO.println s!"  [FAIL] 'x-goog-api-key' header missing or incorrect. Got: {authHeader}"
        failures := failures + 1
      else
        IO.println "  [PASS] 'x-goog-api-key' header verified."
        
      -- Cleanup
      let _ ← IO.FS.removeFile logFile
      return if failures == 0 then 0 else 1
      
  | .error e =>
    IO.println s!"  [FAIL] Failed to parse mock log: {e}"
    return 1

end Pakila.Test
