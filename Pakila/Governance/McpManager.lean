import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Environment

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila.Governance.McpManager

open Lean hiding Message

/-- MCPサーバーの情報 -/
structure McpServerInfo where
  name : String
  command : String
  args : List String
  connected : Bool := true
deriving Repr, Inhabited

/-- ディレクトリを再帰的に走査して MCP 設定ファイルを収集する -/
partial def findMcpConfigs (dir : System.FilePath) : IO (List System.FilePath) := do
  if !(← dir.pathExists) then return []
  let mut configs := []
  let entries ← dir.readDir
  for entry in entries do
    if ← entry.path.isDir then
      let subConfigs ← findMcpConfigs entry.path
      configs := configs ++ subConfigs
    else if entry.fileName == "mcp_config.json" then
      configs := entry.path :: configs
  return configs

/-- 
Gemini CLI のプラグインディレクトリ (<configDir>/config/plugins) から 
MCP サーバー情報を動的に抽出する。
-/
def listConfiguredMcpServers (configDir : System.FilePath) : IO (List McpServerInfo) := do
  let pluginsDir := configDir / "config" / "plugins"
  
  if !(← pluginsDir.pathExists) then return []
  let configFiles ← findMcpConfigs pluginsDir
  let mut allServers := []
  
  for file in configFiles do
    let content ← TerminalEnv.readFile file
    match Json.parse content with
    | .ok json =>
        if let .ok mcpObj := json.getObjVal? "mcpServers" then
          match mcpObj with
          | .obj fields =>
              for (name, conf) in fields.toArray do
                let cmd := match conf.getObjValAs? String "command" with | .ok s => s | _ => ""
                let args := match conf.getObjVal? "args" with 
                  | .ok (.arr a) => a.toList.filterMap (fun j => match j with | .str s => some s | _ => none)
                  | _ => []
                allServers := { name := name, command := cmd, args := args } :: allServers
          | _ => pure ()
    | .error _ => pure ()
    
  return allServers

end Pakila.Governance.McpManager
