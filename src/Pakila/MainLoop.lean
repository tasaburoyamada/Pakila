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
import Pakila.Governance.SkillManager

open Pakila
open Pakila.Protocol
open Lyceum
open Lean hiding Message

namespace Pakila

/-- 履歴が長くなった場合に自動要約を行うヘルパー -/
def checkAndSummarizeState (s : InterpreterState) : IO InterpreterState := do
  if s.history.length >= 20 then
    match ← Core.Summarizer.summarizeHistory s.activeLlm s.history with
    | .ok summaryMsg =>
        let sysMsg := s.history.headD (Lyceum.Message.mkText .system "")
        pure { s with history := [sysMsg, summaryMsg] }
    | .error _ => pure s
  else
    pure s

/-- 形式検証可能なステートマシンループ -/
partial def runLoop (maxTurns : Nat) (config : AppConfig) (s : InterpreterState) (dispatcher : Dispatcher) (categories : List (String × List (String × LlmInstance))) : IO Unit := do
  if maxTurns == 0 then
    IO.println "Max turns reached."
    return

  TerminalEnv.renderUserTurn ""
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
          let nextS := { s with history := s.history.take (s.history.length - 2) }
          IO.println "[System]: Rewound 1 turn."
          runLoop (maxTurns - 1) config nextS dispatcher categories
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
          else IO.println "[Error]: Missing model name."; runLoop (maxTurns - 1) config s dispatcher categories
        else
          runLoop (maxTurns - 1) config s dispatcher categories
      | none =>
        if input.startsWith "/" then
          IO.println s!"[Error]: Command not found."
          runLoop (maxTurns - 1) config s dispatcher categories
        else
          Pakila.renderUserTurn input
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
