import Lean.Data.Json
import Pakila.Core.Machine
import Pakila.Core.State
import Pakila.Core.Interpreter
import Pakila.Core.Dispatcher
import Pakila.Core.Summarizer
import Pakila.CLI.Terminal
import Pakila.CLI.Theme
import Pakila.CLI.Renderer
import Pakila.Protocol.Types
import Pakila.CLI.SlashCommands
import Pakila.CLI.MemoryUI
import Pakila.CLI.Exporter
import Pakila.CLI.SettingsUI
import Pakila.CLI.RewindUI
import Pakila.Governance.SkillManager

import Pakila.Core.Persistence

open Pakila
open Pakila.Protocol
open Lyceum
open Lean hiding Message

namespace Pakila

/-- 履歴が長くなった場合に自動要約を行い、セッション状態を原子的に保存するヘルパー -/
def checkAndSummarizeState (s : InterpreterState) : IO InterpreterState := do
  saveSession s
  if s.history.length >= 20 then
    match ← Core.Summarizer.summarizeHistory s.activeLlm s.history with
    | .ok summaryMsg =>
        let sysMsg := s.history.headD (Lyceum.Message.mkText .system "")
        let updated := { s with history := [sysMsg, summaryMsg] }
        saveSession updated
        pure updated
    | .error _ => pure s
  else
    pure s

/-- 形式検証可能なステートマシンループ -/
partial def runLoop (maxTurns : Nat) (config : AppConfig) (s : InterpreterState) (dispatcher : Dispatcher) (categories : List (String × List (String × LlmInstance))) : IO Unit := do
  if maxTurns == 0 then
    IO.println "Max turns reached."
    return

  let inputOpt ← readLineWithHistory (applyColor .cyan "User > ") s.configDir
  
  match inputOpt with
  | none => 
      IO.println "Exiting..."
      return
  | some input =>
      match Pakila.CLI.parseSlashCommand input with
      | some parsedCmd =>
        let cmd := parsedCmd.cmd
        IO.println s!"[Command]: {cmd.description}"
        if cmd.name == "quit" || cmd.name == "exit" then
          IO.println "Exiting..."
          return
        else if cmd.name == "rewind" then
          match ← Pakila.CLI.RewindUI.runRewindBrowser s.configDir with
          | some target =>
              let nextS := { s with history := s.history.take (max 1 (s.history.length - 2)) }
              IO.println s!"[System]: Rewound session to {target}."
              runLoop (maxTurns - 1) config nextS dispatcher categories
          | none =>
              runLoop (maxTurns - 1) config s dispatcher categories
        else if cmd.name == "export" then
          let args := parsedCmd.args
          let filename := if args.length > 0 then args[0]! else "session_report.md"
          let exportPath := s.configDir / filename
          match ← exportToMarkdown exportPath s.history with
          | Except.ok _ =>
              IO.println s!"[System]: Session history successfully exported to: {exportPath}"
          | Except.error e =>
              IO.println s!"[Error]: Export failed: {repr e}"
          runLoop (maxTurns - 1) config s dispatcher categories
        else if cmd.name == "help" then
          let (termCols, _) ← TerminalEnv.getTerminalSize
          let helpText := Pakila.CLI.availableSlashCommands.foldl (fun acc c => acc ++ s!"/{c.name} - {c.description}\n") ""
          TerminalEnv.println (renderCardBox "Pakila Slash Commands Help" helpText (termWidth := termCols))
          runLoop (maxTurns - 1) config s dispatcher categories
        else if cmd.name == "memory" then
          Pakila.CLI.MemoryUI.runMemoryManager s.configDir s.configDir
          runLoop (maxTurns - 1) config s dispatcher categories
        else if cmd.name == "config" then
          let newConfig ← Pakila.CLI.SettingsUI.runSettingsEditor config
          runLoop (maxTurns - 1) newConfig s dispatcher categories
        else if cmd.name == "clear" then
          TerminalEnv.print "\x1b[2J\x1b[H"
          runLoop (maxTurns - 1) config s dispatcher categories
        else if cmd.name == "reset" then
          let nextS := { s with history := s.history.take 1 }
          IO.println "[System]: Session reset."
          runLoop (maxTurns - 1) config nextS dispatcher categories
        else if cmd.name == "model" then
          let args := parsedCmd.args
          if args.length > 0 then
              let modelName := args[0]!
              let allModels := categories.foldl (fun acc (_, ms) => acc ++ ms) []
              match allModels.find? (fun p => p.1 == modelName) with
              | some m => 
                  let nextS := { s with activeModelName := m.1, activeLlm := m.2 }
                  IO.println s!"[System]: Model switched to {m.1}."
                  runLoop (maxTurns - 1) config nextS dispatcher categories
              | none => IO.println s!"[Error]: Model '{modelName}' not found."; runLoop (maxTurns - 1) config s dispatcher categories
          else
            let mut options : List (String × (String × LlmInstance)) := []
            for (cat, models) in categories do
              for (name, inst) in models do
                options := options ++ [(s!"[{cat}] {name}", (name, inst))]
            if options.isEmpty then
              IO.println "[Error]: No models available."
              runLoop (maxTurns - 1) config s dispatcher categories
            else
              let optStrings := options.map (·.1)
              match (← Pakila.CLI.Prompts.selectOption "モデルを選択してください:" optStrings) with
              | some idx =>
                  if let some (mName, mLlm) := options[idx]?.map (·.2) then
                    let nextS := { s with activeModelName := mName, activeLlm := mLlm }
                    IO.println s!"[System]: Model switched to {mName}."
                    runLoop (maxTurns - 1) config nextS dispatcher categories
                  else
                    runLoop (maxTurns - 1) config s dispatcher categories
              | none =>
                  IO.println "[System]: Model selection cancelled."
                  runLoop (maxTurns - 1) config s dispatcher categories
        else
          runLoop (maxTurns - 1) config s dispatcher categories
      | none =>
        if input.startsWith "/" then
          IO.println s!"[Error]: Command not found."
          runLoop (maxTurns - 1) config s dispatcher categories
        else
          -- 2. 状態遷移 (論理界: 純粋関数・証明可能)
          let (action, nextS) := Pakila.transition s [.text input]

          -- 3. アクション実行 (物理界: バグ発生源)
          match action with
          | .CallLlm _ =>
            -- LLM呼び出しの場合、StructuredLlmResponseを期待
            match ← Pakila.runAction action dispatcher s.activeLlm with
            | Except.ok jsonStr =>
              match Json.parse jsonStr with
              | .ok json =>
                match fromJson? (α := StructuredLlmResponse) json with
                | .ok structuredResponse =>
                  Pakila.renderAiThinking structuredResponse.thought
                  if structuredResponse.hasLlmError then
                    TerminalEnv.println (applyColor .red s!"[Error]: LLM generated an internal error message: {if structuredResponse.action.isSome then structuredResponse.action.get! else structuredResponse.response}")
                    runLoop (maxTurns - 1) config nextS dispatcher categories
                  else if let some act := structuredResponse.action then
                    Pakila.renderAiAction act
                    -- 実際にactをBashコマンドとして実行
                    match ← Pakila.runAction (.ExecuteBash act) dispatcher s.activeLlm with
                    | Except.ok bashOutput =>
                      Pakila.renderSystemOutput bashOutput
                      let toolMsg : Lyceum.Message := { role := .tool, parts := [.text bashOutput] }
                      let nextSWithToolOutput := { nextS with history := nextS.history ++ [toolMsg] }
                      Pakila.renderAiResponse structuredResponse.response
                      let feedbackMsg : Lyceum.Message := { role := .assistant, parts := [.text structuredResponse.response] }
                      let nextSWithFeedback := { nextSWithToolOutput with history := nextSWithToolOutput.history ++ [feedbackMsg] }
                      let finalS ← checkAndSummarizeState nextSWithFeedback
                      runLoop (maxTurns - 1) config finalS dispatcher categories
                    | Except.error e =>
                      Pakila.renderSystemOutput s!"Bash command failed: {e}"
                      TerminalEnv.println (applyColor .red s!"[Error]: Bash command execution failed: {e}")
                      let feedbackMsg : Lyceum.Message := { role := .tool, parts := [.text s!"Bash command failed: {e}"] }
                      let nextSWithFeedback := { nextS with history := nextS.history ++ [feedbackMsg] }
                      let finalS ← checkAndSummarizeState nextSWithFeedback
                      runLoop (maxTurns - 1) config finalS dispatcher categories
                  else -- Bashアクションがなかった場合
                    Pakila.renderAiResponse structuredResponse.response
                    let feedbackMsg : Lyceum.Message := { role := .assistant, parts := [.text structuredResponse.response] }
                    let nextSWithFeedback := { nextS with history := nextS.history ++ [feedbackMsg] }
                    let finalS ← checkAndSummarizeState nextSWithFeedback
                    runLoop (maxTurns - 1) config finalS dispatcher categories
                | .error e =>
                  TerminalEnv.println (applyColor .red s!"[Error]: Failed to parse structured LLM response: {e}")
                  runLoop (maxTurns - 1) config nextS dispatcher categories
              | .error e =>
                TerminalEnv.println (applyColor .red s!"[Error]: Failed to parse LLM response JSON: {e}")
                runLoop (maxTurns - 1) config nextS dispatcher categories
            | Except.error e =>
              TerminalEnv.println (applyColor .red s!"[Error]: LLM Action failed: {e}")
              runLoop (maxTurns - 1) config nextS dispatcher categories
          | _ => -- その他のアクションは直接実行して結果を表示
            match ← Pakila.runAction action dispatcher s.activeLlm with
            | Except.ok "Quit" => do
                (← IO.getStdout).flush
                (← IO.getStderr).flush
                IO.println "Exiting..."
            | Except.ok out =>
                Pakila.renderSystemOutput out
                let role := match action with | .CallLlm _ => Lyceum.Role.assistant | _ => Lyceum.Role.tool
                let feedbackMsg : Lyceum.Message := { role := role, parts := [.text out] }
                let nextSWithFeedback := { nextS with history := nextS.history ++ [feedbackMsg] }
                let finalS ← checkAndSummarizeState nextSWithFeedback
                runLoop (maxTurns - 1) config finalS dispatcher categories
            | Except.error e =>
                TerminalEnv.println (applyColor .red s!"[Error]: Action failed: {e}")
                let feedbackMsg : Lyceum.Message := { role := .tool, parts := [.text s!"Error: {e}"] }
                let nextSWithFeedback := { nextS with history := nextS.history ++ [feedbackMsg] }
                let finalS ← checkAndSummarizeState nextSWithFeedback
                runLoop (maxTurns - 1) config finalS dispatcher categories

end Pakila
