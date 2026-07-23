import Pakila.Core.Primitives
import Lyceum.Core.Environment -- Now TerminalEnv comes from here
import Lyceum.Inference
import Lyceum.Inference.Gemini
import Lyceum.Types
import Pakila.Governance.McpManager
import Pakila.Plugins.FFI
import Lyceum.Tokenizer.Vocab

open Lyceum
open Pakila
open Lyceum.Tokenizer
open Lyceum.Core.Environment
 -- Open new namespace for TerminalEnv

namespace Pakila

/-- LLMマネージャの具象表現 -/
structure LlmManager' where
  activeBackend : String
  backends : List (String × LlmInstance)
deriving Repr, Inhabited

/-- 
  LlmBackend インスタンス
  複雑さ判定 (decideHybridBackend) などの余計なレイヤーを完全に排除し、
  指定された LlmInstance の物理推論をダイレクトにトリガーする。
-/
instance : LlmBackend LlmInstance where
  streamChatCompletion self history options := 
    match self with
    | .remote c => LlmBackend.streamChatCompletion c history options
    | .localEngine c => LlmBackend.streamChatCompletion c history options
    | .mcp c => LlmBackend.streamChatCompletion c history options

  streamContext self ctx start len :=
    match self with
    | .remote c => LlmBackend.streamContext c ctx start len
    | .localEngine c => LlmBackend.streamContext c ctx start len
    | .mcp c => LlmBackend.streamContext c ctx start len

  listModels self :=
    match self with
    | .remote c => LlmBackend.listModels c
    | .localEngine c => LlmBackend.listModels c
    | .mcp c => LlmBackend.listModels c

def LlmInstance.updateApiKey (self : LlmInstance) (key : String) : LlmInstance :=
  match self with
  | .remote c => .remote { c with apiKey := key }
  | .localEngine c => .localEngine c
  | .mcp c => .mcp { c with apiKey := key }

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

def LlmManager'.setActiveBackend [Monad m] [Lyceum.Core.TerminalEnv m] (self : LlmManager') (name : String) : m (Except Lyceum.AppError LlmManager') := do -- Updated TerminalEnv path
  if self.backends.any (fun (n, _) => n == name) then
    return Except.ok { self with activeBackend := name }
  else
    return Except.error (Lyceum.AppError.ConfigError s!"Backend '{name}' not registered.")

/-- カテゴリ別にモデルを検索・取得する -/
def discoverCategorizedModels (apiKey : String) (apiUrl : String) (configDir : System.FilePath) : IO (List (String × List (String × LlmInstance))) := do
  let mut categories : List (String × List (String × LlmInstance)) := []
  let remoteClient : LlmClient := { apiUrl := apiUrl, apiKey := apiKey, modelName := none }
  let localClient : LlmClient := { apiUrl := "", apiKey := "", modelName := none }
  
  match (← LlmBackend.listModels localClient) with
  | Except.ok names =>
    if !List.isEmpty names then
      let home ← IO.getEnv "HOME"
      let modelsDir := System.FilePath.mk (home.getD "." ++ "/models")
      let models : List (String × LlmInstance) := names.filter (fun n => !n.contains "mmproj") |>.map (fun n => 
        (n, LlmInstance.localEngine { localClient with modelName := some (modelsDir / n).toString })
      )
      if !List.isEmpty models then
        categories := categories ++ [("Local Models", models)]

  | Except.error _ => pure ()

  let mcpServers ← Pakila.Governance.McpManager.listConfiguredMcpServers configDir
  if !List.isEmpty mcpServers then
    let models : List (String × LlmInstance) := mcpServers.map (fun s => (s.name, LlmInstance.mcp { remoteClient with modelName := some s.name }))
    categories := categories ++ [("Local MCP", models)]

  if !String.isEmpty apiKey then
    match (← LlmBackend.listModels remoteClient) with
    | Except.ok names =>
      if !List.isEmpty names then
        let models : List (String × LlmInstance) := names.map (fun n => (n, LlmInstance.remote { remoteClient with modelName := some n }))
        categories := categories ++ [("Gemini API", models)]
    | Except.error _ => pure ()

  return categories

end Pakila
