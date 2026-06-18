import Pakila.Core.Primitives
import Pakila.Core.Interface
import Lyceum.Inference
import Lyceum.Inference.Gemini
import Lyceum.Types
import Pakila.Plugins.LocalLeanTensor
import Pakila.Governance.McpManager
import Pakila.Plugins.FFI

open Lyceum
open Pakila

namespace Pakila

/-- LLMインスタンスの具象表現 -/
inductive LlmInstance' where
  | remote (c : LlmClient)
  | localEngine (c : LocalLeanTensorLlm)
  | mcp (c : LlmClient)
  | hybrid (remote : LlmClient) (localEngine : LocalLeanTensorLlm)
deriving Repr

instance : Inhabited LlmInstance' where
  default := .remote default

/-- LLMマネージャの具象表現 -/
structure LlmManager' where
  activeBackend : String
  backends : List (String × LlmInstance')
deriving Repr, Inhabited

/-- ディスパッチャの判定ロジック -/
def decideHybridBackend (history : List Message) (inst : LlmInstance') : LlmInstance' :=
  match inst with
  | .hybrid r l =>
      let isComplex := history.any (fun msg => 
        msg.parts.any (fun part => 
          match part with
          | .text t => t.contains "proof" || t.contains "quantum" || t.contains "complex"
          | _ => false
        )
      )
      if isComplex then .remote r else .localEngine l
  | other       => other

instance : LlmBackend LlmInstance' where
  streamChatCompletion self history options := 
    match decideHybridBackend history self with
    | .remote _c => pure (Except.error (Lyceum.AppError.LlmError "Remote inference disabled by policy."))
    | .localEngine c => LlmBackend.streamChatCompletion c history options
    | .mcp c => LlmBackend.streamChatCompletion c history options
    | .hybrid r _l => LlmBackend.streamChatCompletion r history options

  streamContext self ctx start len :=
    match decideHybridBackend [] self with
    | .remote _c => pure (Except.error (Lyceum.AppError.LlmError "Remote inference disabled by policy."))
    | .localEngine c => LlmBackend.streamContext c ctx start len
    | .mcp c => LlmBackend.streamContext c ctx start len
    | .hybrid r _l => LlmBackend.streamContext r ctx start len

  listModels self :=
    match decideHybridBackend [] self with
    | .remote _c => pure (Except.ok [])
    | .localEngine c => LlmBackend.listModels c
    | .mcp c => LlmBackend.listModels c
    | .hybrid _r l => LlmBackend.listModels l

def LlmInstance'.updateApiKey (self : LlmInstance') (key : String) : LlmInstance' :=
  match self with
  | .remote c => .remote { c with apiKey := key }
  | .localEngine c => .localEngine c
  | .mcp c => .mcp { c with apiKey := key }
  | .hybrid r l => .hybrid { r with apiKey := key } l

-- 修正: 戻り値を純粋な IO にし、unsafeCast を排除
def LlmManager'.streamChatCompletion (self : LlmManager') (history : List Message) (options : Option LlmRequestOptions) : IO (Except Lyceum.AppError (List Message)) := do
  match self.backends.find? (fun (name, _) => name == self.activeBackend) with
  | some (_, inst) => LlmBackend.streamChatCompletion inst history options
  | none => return Except.error (Lyceum.AppError.LlmError s!"Active backend '{self.activeBackend}' not found.")

-- 修正: 戻り値を純粋な IO にし、unsafeCast を排除
def LlmManager'.listModels (self : LlmManager') : IO (Except Lyceum.AppError (List String)) := do
  match self.backends.find? (fun (name, _) => name == self.activeBackend) with
  | some (_, inst) => LlmBackend.listModels inst
  | none => return Except.error (Lyceum.AppError.LlmError s!"Active backend '{self.activeBackend}' not found.")

def LlmManager'.setActiveBackend [Monad m] [TerminalEnv m] (self : LlmManager') (name : String) : m (Except Lyceum.AppError LlmManager') := do
  if self.backends.any (fun (n, _) => n == name) then
    return Except.ok { self with activeBackend := name }
  else
    return Except.error (Lyceum.AppError.ConfigError s!"Backend '{name}' not registered.")

/-- カテゴリ別にモデルを検索・取得する -/
def discoverCategorizedModels (apiKey : String) (apiUrl : String) (configDir : System.FilePath) : IO (List (String × List (String × LlmInstance'))) := do
  let mut categories : List (String × List (String × LlmInstance')) := []
  let remoteClient : LlmClient := { apiUrl := apiUrl, apiKey := apiKey, modelName := none }
  let localClient : LocalLeanTensorLlm := { modelPath := "", mmprojPath := none, tokenizerInstance := { modelName := "", vocab := Tokenizer.emptyVocab } }

  match (← LlmBackend.listModels localClient) with
  | Except.ok names =>
    if !List.isEmpty names then
      let home ← IO.getEnv "HOME"
      let modelsDir := System.FilePath.mk (home.getD "." ++ "/models")
      let mmprojPath := names.find? (fun n => n.contains "mmproj") |>.map (fun n => (modelsDir / n).toString)
      let models : List (String × LlmInstance') := names.filter (fun n => !n.contains "mmproj") |>.map (fun n => 
        (n, LlmInstance'.localEngine { localClient with modelPath := (modelsDir / n).toString, mmprojPath := mmprojPath })
      )
      if !List.isEmpty models then
        categories := categories ++ [("Local Models", models)]
        let firstModel := models.head!
        match firstModel.2 with
        | .localEngine l =>
            let hybridModel := ("Hybrid (Auto)", LlmInstance'.hybrid remoteClient l)
            categories := categories ++ [("Hybrid", [hybridModel])]
        | _ => pure ()
  | Except.error _ => pure ()

  let mcpServers ← Pakila.Governance.McpManager.listConfiguredMcpServers configDir
  if !List.isEmpty mcpServers then
    let models : List (String × LlmInstance') := mcpServers.map (fun s => (s.name, LlmInstance'.mcp { remoteClient with modelName := some s.name }))
    categories := categories ++ [("Local MCP", models)]

  if !String.isEmpty apiKey then
    match (← LlmBackend.listModels remoteClient) with
    | Except.ok names =>
      if !List.isEmpty names then
        let models : List (String × LlmInstance') := names.map (fun n => (n, LlmInstance'.remote { remoteClient with modelName := some n }))
        categories := categories ++ [("Gemini API", models)]
    | Except.error _ => pure ()

  return categories

end Pakila
