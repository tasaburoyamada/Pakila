import Lean.Data.Json
import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

open Pakila
open Lean hiding Message

def runTest (name : String) (test : IO (Except String Unit)) : IO Unit := do
  IO.println s!"Running test: {name}..."
  match (← test) with
  | .ok _ => IO.println s!"[PASS] {name}"
  | .error e => IO.println s!"[FAIL] {name}: {e}"

/-- Gemini Protocol: メッセージ変換の検証 -/
def testMessagesToGemini : IO (Except String Unit) := do
  let history : List Pakila.Message := [
    Pakila.Message.mkText .system "System Instruction",
    { role := .user, parts := [
        .text "Describe this image",
        .image "image/png" ([0x89, 0x50, 0x4E].toByteArray)
      ] 
    }
  ]
  
  let (system, contents) ← messagesToGemini history
  
  -- システムプロンプトの検証
  match system with
  | some c => 
      if c.role != "system" then return Except.error "Invalid system role"
      match c.parts with
      | GeminiPart.text t :: _ => if t != "System Instruction" then return Except.error "System text mismatch"
      | _ => return Except.error "System text part not found"
  | none => return Except.error "System instruction not found"

  -- ユーザーメッセージの検証
  if contents.length != 1 then return Except.error s!"Expected 1 user message, got {contents.length}"
  match contents with
  | userMsg :: _ =>
    if userMsg.parts.length != 2 then return Except.error "Expected 2 parts in user message"
  | _ => return Except.error "User message not found"
  
  return Except.ok ()

/-- Gemini Protocol: レスポンスパースの検証 -/
def testResponseParsing : IO (Except String Unit) := do
  let rawResponse := "{
    \"candidates\": [
      {
        \"content\": {
          \"parts\": [
            { \"text\": \"Hello from Gemini\" },
            { 
              \"inline_data\": {
                \"mime_type\": \"image/png\",
                \"data\": \"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==\"
              }
            }
          ],
          \"role\": \"model\"
        }
      }
    ]
  }"
  
  match Json.parse rawResponse with
  | .ok json =>
      let navigate : Except String (List Json) := do
        let candidates ← json.getObjVal? "candidates"
        let first ← candidates.getArrVal? 0
        let content ← first.getObjVal? "content"
        let parts ← content.getObjVal? "parts"
        let arr ← parts.getArr?
        return arr.toList

      match navigate with
      | .ok partList =>
          let mut messageParts : List MessagePart := []
          for p in partList do
            if let some mp ← geminiPartToMessage p then
              messageParts := mp :: messageParts
          
          let result := messageParts.reverse
          if result.length != 2 then return Except.error s!"Expected 2 parts, got {result.length}"
          match result with
          | MessagePart.text t :: MessagePart.image mime _ :: _ =>
              if t != "Hello from Gemini" then return Except.error "Text mismatch"
              if mime != "image/png" then return Except.error "MIME mismatch"
          | _ => return Except.error "Message parts structure mismatch"
          
          return Except.ok ()
      | .error e => return Except.error s!"Navigation failed: {e}"
  | .error e => return Except.error s!"JSON parse failed: {e}"

def main : IO Unit := do
  IO.println "=== Pakila Gemini Protocol Test Suite ==="
  runTest "MessagesToGemini" testMessagesToGemini
  runTest "ResponseParsing" testResponseParsing
