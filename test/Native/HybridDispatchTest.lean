import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.LlmManager
import Pakila.Plugins.LocalLeanTensor

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

namespace Pakila.Test.Native

def testHybridDispatchRouting : IO UInt32 := do
  IO.println "--- Test: Hybrid Dispatcher Routing Heuristics ---"
  
  let r : LlmClient := { apiUrl := "http://dummy", apiKey := "key", modelName := some "gemini" }
  let l : LocalLeanTensorLlm := { modelPath := "local.gguf", mmprojPath := none, tokenizerInstance := { modelName := "tok", vocab := Tokenizer.emptyVocab } }
  let hybrid := LlmInstance.hybrid r l
  
  -- Case 1: Short message (should route to local)
  let history1 := [Message.mkText .user "Hi"]
  let instance1 := decideHybridBackend history1 hybrid
  let isLocal := match instance1 with | .localEngine _ => true | _ => false
  
  -- Case 2: Complex message (should route to remote)
  let history2 := [Message.mkText .user "Please design a complex architecture for a distributed system."]
  let instance2 := decideHybridBackend history2 hybrid
  let isRemote := match instance2 with | .remote _ => true | _ => false
  
  if isLocal && isRemote then
    IO.println "  [PASS] Routing logic correctly identified complexity."
    return 0
  else
    IO.println s!"  [FAIL] Routing failed. Case 1 (Local): {isLocal}, Case 2 (Remote): {isRemote}"
    return 1

def testLocalNativeInference : IO UInt32 := do
  IO.println "--- Test: Local Native Inference FFI Integration ---"
  let l : LocalLeanTensorLlm := { modelPath := "local.gguf", mmprojPath := none, tokenizerInstance := { modelName := "tok", vocab := Tokenizer.emptyVocab } }
  
  let res ← LlmBackend.streamChatCompletion l [] none
  match res with
  | .ok msgs =>
      let firstPart := msgs.head!.parts.head!
      let text := match firstPart with | .text t => t | _ => ""
      if text.contains "FFI Checksum: 19200" then -- 192.0 * 100 iterations
        IO.println s!"  [PASS] Native inference returned correct FFI checksum: {text}"
        return 0
      else
        IO.println s!"  [FAIL] Native inference returned incorrect result: {text}"
        return 1
  | .error e =>
      IO.println s!"  [FAIL] Native inference failed with error: {repr e}"
      return 1

end Pakila.Test.Native
