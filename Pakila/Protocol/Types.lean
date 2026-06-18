import Lean
import Lean.Data.Json
import Lyceum.Types

namespace Pakila.Protocol

open Lean hiding Message
open Lyceum

inductive GovernanceAction where
  | AuditIntegrity
  | SelfHeal
  | CheckEngine
  | VerifyIntegrity
  | ShowSettings
deriving Repr, BEq, Inhabited, ToJson, FromJson

inductive MachineAction where
  | Quit
  | CallLlm (msgs : List Message)
  | ExecuteBash (cmd : String)
  | Governance (action : GovernanceAction)
  | WriteFile (path : String) (content : String)
  | ReadFile (path : String) (startLine : Option Nat := none) (endLine : Option Nat := none)
  | SearchMemory (query : String) (limit : Nat)
  | StoreMemory (key : String) (value : String)
  | ActivateSkill (name : String)
  | EditImage (file : String) (prompt : String)
  | RestoreImage (file : String) (prompt : String)
  | GenerateIcon (prompt : String) (sizes : List Nat)
  | GenerateDiagram (prompt : String) (diagType : String)
  | InvokeAgent (prompt : String)
  | RunTest (testCommand : String)
deriving Repr, BEq, Inhabited, ToJson, FromJson

/-- 構造化されたLLM応答 -/
structure StructuredLlmResponse where
  thought : String
  action : Option String -- 例えばbashコマンド
  response : String
deriving Repr, BEq, Inhabited, ToJson, FromJson

/-- LLMの生応答を解析し、StructuredLlmResponse を抽出する -/
def parseStructuredLlmResponse (rawResponse : String) : StructuredLlmResponse := Id.run do
  let mut thought := ""
  let mut action : Option String := none
  let mut response := ""

  let lines := rawResponse.splitOn "\n"
  let mut currentSection := ""
  let mut currentActionLines : List String := []

  for line in lines do
    let trimmedLine := line.trimAscii.toString
    if trimmedLine.startsWith "## Thought" then
      currentSection := "thought"
    else if trimmedLine.startsWith "## Action" then
      currentSection := "action"
    else if trimmedLine.startsWith "## Response" then
      currentSection := "response"
    else
      match currentSection with
      | "thought" => thought := thought ++ line ++ "\n"
      | "action" =>
          -- ここで ```bash ... ``` を検出してactionを抽出
          if trimmedLine.startsWith "```bash" then
            currentActionLines := []
          else if trimmedLine.startsWith "```" then
            action := some (String.intercalate "\n" currentActionLines)
            currentActionLines := []
          else if action.isNone then
            currentActionLines := currentActionLines ++ [line]
          else
            -- If action already extracted, treat subsequent lines as part of response
            response := response ++ line ++ "\n"
      | "response" => response := response ++ line ++ "\n"
      | _ =>
          -- No section header yet, or invalid section, treat as part of thought
          if thought.isEmpty then thought := thought ++ line ++ "\n"
          else response := response ++ line ++ "\n" -- If thought already started, this might be a leading part of response

  -- Clean up extra newlines
  thought := thought.trim
  response := response.trim

  -- If action was never explicitly extracted, but actionLines accumulated, try to set it
  if action.isNone && !currentActionLines.isEmpty then
    action := some (String.intercalate "\n" currentActionLines)

  return { thought := thought, action := action, response := response }

end Pakila.Protocol
