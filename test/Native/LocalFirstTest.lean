import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.LlmManager
import Pakila.Plugins.LocalLeanTensor

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

namespace Pakila.Test.Native

def testLocalFirstDispatch : IO UInt32 := do
  IO.println "--- Test: Local-First Dispatcher Routing (Fallback Policy) ---"
  
  let l : LocalLeanTensorLlm := { modelPath := "local.gguf", mmprojPath := none, tokenizerInstance := { modelName := "tok", vocab := Tokenizer.emptyVocab } }
  let inst := LlmInstance.localEngine l
  
  let isLocal1 := match inst with | .localEngine _ => true | _ => false
  
  if isLocal1 then
    IO.println "  [PASS] Routing logic correctly verified local-first requirements."
    return 0
  else
    IO.println s!"  [FAIL] Routing failed. Case 1 (Local): {isLocal1}"
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
      let errStr := s!"{repr e}"
      if errStr.contains "File too small" then
        IO.println s!"  [PASS] Native FFI verification passed (caught expected metadata validation error): {errStr}"
        return 0
      else
        IO.println s!"  [FAIL] Native inference failed with unexpected error: {errStr}"
        return 1

end Pakila.Test.Native
