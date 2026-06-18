import Lean.Data.Json
import Pakila.Core.Machine
import Pakila.Core.State
import Pakila.Core.Interpreter
import Pakila.Core.Dispatcher
import Pakila.CLI.Terminal
import Pakila.CLI.Theme
import Pakila.CLI.Renderer
import Pakila.Protocol.Types -- StructuredLlmResponse と parseStructuredLlmResponse をインポート

open Pakila
open Pakila.Protocol
open Lyceum
open Lean hiding Message

namespace Pakila

/-- 形式検証可能なステートマシンループ -/
partial def runLoop (maxTurns : Nat) (config : AppConfig) (s : InterpreterState) (dispatcher : Dispatcher) : IO Unit := do
  if maxTurns == 0 then
    IO.println "Max turns reached."
    return

  -- 1. ユーザー入力を受け取る
  -- 最初のプロンプトはApp.leanでロゴ表示後にTerminalEnv.printlnされるため、ここでは空文字列でUserターンを開始
  Pakila.renderUserTurn ""
  let inputOpt ← readLineWithHistory (applyColor .cyan "User > ") s.configDir
  let input ← match inputOpt with
    | some i => pure i
    | none => -- EOF or Ctrl+D
      IO.println "Exiting..."
      return

  Pakila.renderUserTurn input -- 実際の入力をレンダリング

  -- 2. 状態遷移 (論理界: 純粋関数・証明可能)
  let (action, nextS) := Pakila.transition s [.text input]

  -- 3. アクション実行 (物理界: バグ発生源)
  match action with
  | .CallLlm msgs =>
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
            runLoop (maxTurns - 1) config nextS dispatcher
          else if let some act := structuredResponse.action then
            Pakila.renderAiAction act
            -- 実際にactをBashコマンドとして実行
            match ← Pakila.runAction (.ExecuteBash act) dispatcher s.activeLlm with
            | Except.ok bashOutput =>
              Pakila.renderSystemOutput bashOutput
              let toolMsg : Lyceum.Message := { role := .tool, parts := [.text bashOutput] }
              let nextSWithToolOutput := { nextS with history := toolMsg :: nextS.history }
              Pakila.renderAiResponse structuredResponse.response
              let feedbackMsg : Lyceum.Message := { role := .assistant, parts := [.text structuredResponse.response] }
              let nextSWithFeedback := { nextSWithToolOutput with history := feedbackMsg :: nextSWithToolOutput.history }
              runLoop (maxTurns - 1) config nextSWithFeedback dispatcher
            | Except.error e =>
              Pakila.renderSystemOutput s!"Bash command failed: {e}"
              TerminalEnv.println (applyColor .red s!"[Error]: Bash command execution failed: {e}")
              let feedbackMsg : Lyceum.Message := { role := .tool, parts := [.text s!"Bash command failed: {e}"] }
              let nextSWithFeedback := { nextS with history := feedbackMsg :: nextS.history }
              runLoop (maxTurns - 1) config nextSWithFeedback dispatcher
          else -- Bashアクションがなかった場合
            Pakila.renderAiResponse structuredResponse.response
            let feedbackMsg : Lyceum.Message := { role := .assistant, parts := [.text structuredResponse.response] }
            let nextSWithFeedback := { nextS with history := feedbackMsg :: nextS.history }
            runLoop (maxTurns - 1) config nextSWithFeedback dispatcher
        | .error e =>
          TerminalEnv.println (applyColor .red s!"[Error]: Failed to parse structured LLM response: {e}")
          runLoop (maxTurns - 1) config nextS dispatcher
      | .error e =>
        TerminalEnv.println (applyColor .red s!"[Error]: Failed to parse LLM response JSON: {e}")
        runLoop (maxTurns - 1) config nextS dispatcher
    | Except.error e =>
      TerminalEnv.println (applyColor .red s!"[Error]: LLM Action failed: {e}")
      runLoop (maxTurns - 1) config nextS dispatcher
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
        let nextSWithFeedback := { nextS with history := feedbackMsg :: nextS.history }
        runLoop (maxTurns - 1) config nextSWithFeedback dispatcher
    | Except.error e =>
        TerminalEnv.println (applyColor .red s!"[Error]: Action failed: {e}")
        let feedbackMsg : Lyceum.Message := { role := .tool, parts := [.text s!"Error: {e}"] }
        let nextSWithFeedback := { nextS with history := feedbackMsg :: nextS.history }
        runLoop (maxTurns - 1) config nextSWithFeedback dispatcher

end Pakila

/-- 非対話型テストループ -/
partial def runTestLoop (s : InterpreterState) (dispatcher : Dispatcher) (inputs : List String) : IO Unit := do
  match inputs with
  | [] => IO.println "Exiting Test Mode (inputs exhausted)."
  | input :: rest =>
    IO.println s!"DEBUG: Testing input: {input}"
    let (action, nextS) := Pakila.transition s [.text input]
    let _ ← Pakila.runAction action dispatcher s.activeLlm
    -- Process the result of the action if needed, then continue
    runTestLoop { nextS with history := [{ role := .tool, parts := [.text s!"Processed: {input}"] }] } dispatcher rest
