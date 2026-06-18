import Pakila
import Pakila.Memory.VectorDB
import Pakila.Memory.NativeEmbedding
import Pakila.Core.DigitalTwin
import Pakila.Core.ContextLoader -- Add this import
import Pakila.CLI.RewindUI
import Pakila.CLI.Prompts
import Pakila.CLI.TerminalBase
import Pakila.Governance.McpManager
import Pakila.Governance.SkillManager
import Pakila.Governance.GitManager
import Pakila.Config.Loader
import Pakila.MainLoop
import Pakila.Core.Environment
import Pakila.Plugins.Dispatcher -- Dispatcher structure
import Pakila.Core.Bash -- BashEngine
import Pakila.Plugins.Sandbox -- SandboxEngine
import Pakila.Core.ResourceManager -- ResourceManager
import Pakila.Plugins.WasmLoader -- WasmPlugin

open Pakila
open Lyceum
open Lean hiding Message
open Pakila.Core.DigitalTwin -- Add this open
open Pakila.CLI.Prompts -- Add this open

namespace Pakila.CLI.App

private def getConfigPath : IO System.FilePath := do
  let localConfig := System.FilePath.mk "config.toml"
  if ← localConfig.pathExists then return localConfig
  let home ← Pakila.Plugins.FFI.getHomeDirectoryNative ()
  let homePath := System.FilePath.mk home
  return homePath / ".config" / "pakila" / "config.toml"

private def expandPath (path : String) : IO System.FilePath := do
  if path.startsWith "~" then
    let home ← Pakila.Plugins.FFI.getHomeDirectoryNative ()
    let homePath := System.FilePath.mk home
    return homePath / (String.drop path 1).toString
  else
    return System.FilePath.mk path

def printStartupLogo (model : String) : IO Unit := do
  let clearSeq := "\x1b[2J\x1b[H"
  let logo := s!"
 \x1b[38;5;74m▝\x1b[38;5;110m▜\x1b[38;5;140m▄\x1b[38;5;139m \x1b[38;5;174m \x1b[39m   \x1b[1m\x1b[38;5;231mPakila CLI\x1b[22m\x1b[38;5;248m v0.43.0\x1b[39m
 \x1b[38;5;74m \x1b[38;5;110m \x1b[38;5;140m▝\x1b[38;5;139m▜\x1b[38;5;174m▄\x1b[39m
 \x1b[38;5;74m \x1b[38;5;110m▗\x1b[38;5;140m▟\x1b[38;5;139m▀\x1b[38;5;174m \x1b[39m   \x1b[1m\x1b[38;5;231mSigned in with Google\x1b[22m\x1b[38;5;248m /auth\x1b[39m
 \x1b[38;5;74m▝\x1b[38;5;110m▀\x1b[38;5;140m  \x1b[38;5;139m \x1b[38;5;174m \x1b[39m  \x1b[1m\x1b[38;5;231mActive Model:\x1b[22m {model}\x1b[38;5;248m /config\x1b[39m
"
  TerminalEnv.print (clearSeq ++ logo ++ "\n")
  let notice := renderNoticeBox "Welcome to Pakila! This environment is optimized for autonomous logic\nexecution and theorem verification. Type /help for more information."
  TerminalEnv.println notice

/-- CLI アプリケーションのメイン実行ロジック -/
def run (args : List String) : IO Unit := do
  let subcommand ← match parseCliArgs args with
    | Except.ok res => pure res
    | Except.error e => TerminalEnv.println s!"[CLI Error]: {repr e}"; return

  match subcommand with
  | .help =>
    TerminalEnv.println "Usage: pakila [options] [command]\n"
    TerminalEnv.println "Pakila CLI - Defaults to interactive mode.\n"
    -- (ヘルプ表示の詳細は Main.lean からの移植を継続)
    return
  | .version => TerminalEnv.println "0.43.0"; return
  | .config =>
    let configPath ← getConfigPath
    if ← configPath.pathExists then
      TerminalEnv.println (← TerminalEnv.readFile configPath)
    else
      TerminalEnv.println "No configuration file found."
    return
  | _ => pure ()

  let configPath ← getConfigPath
  let currentConfigDir := configPath.parent.getD "."
  let config ← match (← loadConfig configPath) with | Except.ok c => pure c | Except.error _ => pure ({} : AppConfig)

  let pattern ← analyzeWorkspace "."
  let workspaceRoot ← IO.currentDir
  let loadedCtx ← resolveFullContext workspaceRoot workspaceRoot currentConfigDir
  let formattedCtx := formatFullContext loadedCtx

  let promptManager : PromptManager := { systemPromptTemplate := config.systemPrompt }
  let sysInfo ← getSystemInfo
  let hookContext ← match (← IO.getEnv "PAKILA_HOOK_CONTEXT") with | some c => pure s!"\n<hook_context>\n{c}\n</hook_context>" | none => pure ""
  let fullSystemPrompt := promptManager.injectInitState sysInfo formattedCtx pattern ++ hookContext

  let mut currentApiKey := config.llmApiKey.getD ""
  if currentApiKey.isEmpty then
    match (← Pakila.CLI.AuthUI.triggerAuthFlow) with | some k => currentApiKey := k | none => pure ()
  let baseUrl := if config.llmApiUrl.isEmpty then "https://generativelanguage.googleapis.com" else config.llmApiUrl

  let remoteClient : LlmClient := { apiUrl := baseUrl, apiKey := currentApiKey, modelName := none }
  let categories ← discoverCategorizedModels currentApiKey baseUrl currentConfigDir

  let (selectedModelName, selectedLlm) ← do
    let allModels := categories.foldl (fun acc (_, ms) => acc ++ ms) []
    if !config.llmModel.isEmpty then
      match allModels.find? (fun p => p.1.contains config.llmModel) with
      | some m => pure m | none => pure ("", .remote remoteClient)
    else if categories.isEmpty then pure ("", .remote remoteClient)
    else if categories.length == 1 && categories[0]!.2.length == 1 then pure categories[0]!.2[0]!
    else
      match (← selectModelFlat categories) with
      | some res => pure res
      | none =>
          if h : !categories.isEmpty && !categories[0]!.2.isEmpty then
            pure categories[0]!.2[0]!
          else
            pure ("", .remote remoteClient)

  if selectedModelName.isEmpty then return

  match subcommand with
  | .run runArgs =>
    let dbPath := currentConfigDir / s!".pakila/sessions/{runArgs.session.getD "current"}/vector_db.json"
    let initialDb ← match (← Pakila.Memory.VectorDB.load dbPath.toString) with | Except.ok db => pure db | Except.error e => pure ∅

    let mut embModel := none
    let bertPath ← expandPath (config.embeddingModelPath.getD "models/bert.gguf")
    if ← bertPath.pathExists then
      match (← Pakila.Memory.initNativeEmbedding bertPath.toString) with
      | Except.ok m => embModel := some m
      | Except.error _ => pure ()

    let initialState : InterpreterState := {
      history := [Message.mkText .system fullSystemPrompt],
      vectorDb := initialDb,
      vlogState := [], -- Add missing field
      embeddingModel := embModel,
      sessionId := runArgs.session.getD "current",
      interactive := runArgs.prompt.isNone && runArgs.query.isEmpty,
      executionMode := if runArgs.prompt.isSome || !runArgs.query.isEmpty then .Batch else .Interactive,
      configDir := currentConfigDir,
      activeLlm := selectedLlm,
      activeModelName := selectedModelName
    }
    let initialInput := match runArgs.prompt with | some p => some p | none => if runArgs.query.isEmpty then none else some (String.intercalate " " runArgs.query)

    -- Dispatcherの構築
    let bashEngine : BashEngine := { cwd := currentConfigDir.toString, env := [] }
    let sandboxEngine : SandboxEngine := { cwd := currentConfigDir.toString, env := [], level := .Low }
    let resourceManager : ResourceManager := {} -- デフォルト値で初期化
    let dispatcher : Dispatcher := {
      bashEngine := bashEngine,
      sandboxEngine := sandboxEngine,
      useSandbox := initialState.sandbox, -- InterpreterStateから設定
      resManager := resourceManager,
      wasmPlugins := [], -- 当面は空
      taskCounter := 0
    }

    let finalState := match initialInput with
      | some input => 
          { initialState with history := initialState.history ++ [Message.mkText .user input] }
      | none => initialState

    printStartupLogo selectedModelName
    runLoop 1000 config finalState dispatcher
  | _ => TerminalEnv.println "Subcommand not fully integrated."

end Pakila.CLI.App
