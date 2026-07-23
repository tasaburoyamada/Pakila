import Lean.Data.Json
import Lyceum.Inference
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State


open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

namespace Pakila.Core.Summarizer

open Lean hiding Message
open Pakila

def roleToString : Role -> String
  | .system    => "System"
  | .user      => "User"
  | .assistant => "Assistant"
  | .tool      => "Tool"

/-- 
対話履歴を要約して圧縮する。
LLM を用いて、これまでの経緯を簡潔な Message に変換する。
-/
def summarizeHistory (client : LlmInstance) (history : List Message) : IO (Except AppError Message) := do
  if history.length < 5 then 
    return Except.ok (history.getLastD (Message.mkText .system "No history"))
  
  let prompt := "Please summarize the following development conversation history into a concise strategic summary. Focus on completed tasks and current goals. Use high-density symbolic language where appropriate."
  let historyText := String.intercalate "\n" (history.map (fun msg => 
    let roleStr := roleToString msg.role
    let text := msg.parts.filterMap (fun p => match p with | .text t => some t | _ => none) |> String.intercalate " "
    s!"[{roleStr}]: {text}"))
  
  let summaryMsg : Message := { 
    role := .user, 
    parts := [.text s!"{prompt}\n\nHISTORY:\n{historyText}"] 
  }
  
  match (← LlmBackend.streamChatCompletion client [summaryMsg] none) with
  | .ok msgs => 
      let res := msgs.getLastD (Message.mkText .system "Summary failed")
      return Except.ok { res with role := .system }
  | .error e => return Except.error e

end Pakila.Core.Summarizer
