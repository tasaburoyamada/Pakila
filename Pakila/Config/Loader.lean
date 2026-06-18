import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.Theme
import Pakila.Core.Environment

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

def defaultTimeoutMs : Nat := 30000

structure AppConfig where
  llmModel : String := ""
  llmApiUrl : String := ""
  llmApiKey : Option String := none
  systemPrompt : String := ""
  embeddingModelPath : Option String := none
  timeoutMs : Option Nat := some defaultTimeoutMs
  debug : Bool := false
  uiTheme : Theme := { user := .cyan, ai := .green, error := .red, system := .yellow }
deriving Repr, Lean.ToJson, Lean.FromJson, Inhabited

/-- 環境変数を取得し、設定をオーバーライドする -/
def overrideWithEnv (config : AppConfig) : IO AppConfig := do
  let model ← IO.getEnv "PAKILA_MODEL"
  let apiUrl ← IO.getEnv "PAKILA_API_URL"
  
  -- セッション環境変数の解決 (優先順位は外部から制御可能にするのが理想だが、ここでは標準的なものを採用)
  let apiKey ← do
    let keys := ["GEMINI_API_KEY", "GOOGLE_API_KEY", "OPENAI_API_KEY"]
    let mut found := none
    for key in keys do
      if let some k ← IO.getEnv key then
        found := some k
        break
    pure (found.or config.llmApiKey)

  let systemPrompt ← IO.getEnv "PAKILA_SYSTEM_PROMPT"
  let bertPath ← IO.getEnv "PAKILA_BERT_PATH"
  let debug ← IO.getEnv "PAKILA_DEBUG"
  let timeout ← IO.getEnv "PAKILA_TIMEOUT"
  
  return { config with 
    llmModel := model.getD config.llmModel,
    llmApiUrl := apiUrl.getD config.llmApiUrl,
    llmApiKey := apiKey,
    systemPrompt := systemPrompt.getD config.systemPrompt,
    embeddingModelPath := bertPath.or config.embeddingModelPath,
    timeoutMs := match timeout with | some s => s.toNat? | none => config.timeoutMs,
    debug := debug.map (fun s => s == "true") |>.getD config.debug
  }

/-- 
簡易的なTOMLパーサー。
key = "value" 形式のみをサポート。
-/
def parseSimpleToml (content : String) : AppConfig :=
  let lines := content.splitOn "\n"
  let rec loop (lines : List String) (config : AppConfig) : AppConfig :=
    match lines with
    | [] => config
    | line :: rest =>
      let line := line.trimAscii.toString
      if line.isEmpty || line.startsWith "#" || line.startsWith "[" then
        loop rest config
      else
        let parts := line.splitOn "="
        if parts.length >= 2 then
          let key := parts[0]!.trimAscii.toString
          let val := parts[1]!.trimAscii.toString
          let val := if val.startsWith "\"" && val.endsWith "\"" then
            val.drop 1 |>.dropEnd 1 |>.toString
          else val
          
          let newConfig := match key with
            | "llmModel" => { config with llmModel := val }
            | "llmApiUrl" => { config with llmApiUrl := val }
            | "llmApiKey" => { config with llmApiKey := some val }
            | "systemPrompt" => { config with systemPrompt := val }
            | "embeddingModelPath" => { config with embeddingModelPath := some val }
            | "timeoutMs" => { config with timeoutMs := val.toNat? }
            | "debug" => { config with debug := (val == "true") }
            | _ => config
          loop rest newConfig
        else
          loop rest config
  loop lines {}

def configToToml (config : AppConfig) : String :=
  let apiKey := match config.llmApiKey with | some k => s!"\"{k}\"" | none => "\"\""
  let bertPath := match config.embeddingModelPath with | some p => s!"\"{p}\"" | none => "\"\""
  let timeout := match config.timeoutMs with | some t => s!"{t}" | none => s!"{defaultTimeoutMs}"
  s!"llmModel = \"{config.llmModel}\"\n" ++
  s!"llmApiUrl = \"{config.llmApiUrl}\"\n" ++
  s!"llmApiKey = {apiKey}\n" ++
  s!"systemPrompt = \"{config.systemPrompt}\"\n" ++
  s!"embeddingModelPath = {bertPath}\n" ++
  s!"timeoutMs = {timeout}\n" ++
  s!"debug = {if config.debug then "true" else "false"}\n"

/-- 設定ファイルを保存する -/
def saveConfig (path : System.FilePath) (config : AppConfig) : IO (Except AppError Unit) := do
  try
    TerminalEnv.writeFile path (configToToml config)
    return Except.ok ()
  catch e =>
    return Except.error (AppError.IoError s!"Failed to save config: {e}")

/-- 設定ファイルを読み込む -/
def loadConfig (path : System.FilePath) : IO (Except AppError AppConfig) := do
  if !(← path.pathExists) then
    let config ← overrideWithEnv {}
    return Except.ok config
  else
    let content ← TerminalEnv.readFile path
    let baseConfig := parseSimpleToml content
    let finalConfig ← overrideWithEnv baseConfig
    return Except.ok finalConfig

end Pakila
