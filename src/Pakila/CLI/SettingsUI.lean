import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.Prompts
import Pakila.CLI.Terminal
import Pakila.Config.Loader
import Pakila.Core.Environment

open Lyceum
open Pakila
open Pakila.CLI.Prompts

--TEMP_MARKER--

namespace Pakila.CLI.SettingsUI

/-- 設定の対話的エディタ -/
partial def runSettingsEditor (config : AppConfig) : IO AppConfig := do
  TerminalEnv.println "--- Pakila Settings Editor ---"
  TerminalEnv.println s!"1. LLM Model:  {config.llmModel}"
  TerminalEnv.println s!"2. API URL:    {config.llmApiUrl}"
  TerminalEnv.println s!"3. API Key:    {if config.llmApiKey.isSome then "********" else "(None)"}"
  TerminalEnv.println s!"4. Debug Mode: {config.debug}"
  TerminalEnv.println "0. Exit and Save"
  
  let choice ← selectOption "Select item to edit (0-4):" ["Exit", "LLM Model", "API URL", "API Key", "Debug Mode"]
  match choice with
  | some 0 | none => return config
  | some 1 => 
      TerminalEnv.print "New Model Name: "
      let val ← (← IO.getStdin).getLine
      runSettingsEditor { config with llmModel := val.trimAscii.toString }
  | some 2 =>
      TerminalEnv.print "New API URL: "
      let val ← (← IO.getStdin).getLine
      runSettingsEditor { config with llmApiUrl := val.trimAscii.toString }
  | some 3 =>
      TerminalEnv.print "New API Key: "
      let val ← (← IO.getStdin).getLine
      runSettingsEditor { config with llmApiKey := some val.trimAscii.toString }
  | some 4 =>
      let val ← yesNo "Enable Debug Mode?"
      runSettingsEditor { config with debug := val }
  | some _ => runSettingsEditor config

end Pakila.CLI.SettingsUI
