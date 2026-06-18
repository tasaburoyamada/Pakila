import Lyceum.Types
import Lyceum.Inference
import Pakila.Config.Loader

open Lyceum

--TEMP_MARKER--

open Pakila

def testConfigAuthParsing : IO UInt32 := do
  IO.println "Running test: Config Authentication Parsing..."
  let tomlContent := "
llmModel = \"models/gemini-2.5-flash\"
llmApiKey = \"test-api-key-123\"
llmApiUrl = \"https://custom.api.com\"
"
  let config := parseSimpleToml tomlContent
  
  if config.llmApiKey == some "test-api-key-123" then
    IO.println "  [PASS] llmApiKey parsed correctly"
    return 0
  else
    IO.println s!"  [FAIL] llmApiKey mismatch. Got: {repr config.llmApiKey}"
    return 1
