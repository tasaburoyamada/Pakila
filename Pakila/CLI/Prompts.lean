import Pakila.CLI.TerminalBase
import Lyceum.Inference
import Pakila.Core.Primitives

namespace Pakila.CLI.Prompts

open Pakila.CLI.TerminalBase
open Pakila

/-- ユーザーにYes/Noで問いかけ、真偽値を返す (汎用版) -/
partial def yesNo {m : Type → Type} [Monad m] [TerminalEnv m] (prompt : String) : m Bool := do
  TerminalEnv.println s!"{prompt} (y/n)"
  let input ← TerminalEnv.readLine
  if input.isEmpty then return false -- EOF
  let input := input.trimAscii.toString
  if input == "y" || input == "Y" || input == "yes" || input == "Yes" || input == "YES" then
    return true
  else if input == "n" || input == "N" || input == "no" || input == "No" || input == "NO" then
    return false
  else 
    TerminalEnv.println "無効な入力です。'y' または 'n' で答えてください。"
    yesNo prompt

/-- ユーザーに選択肢を提示し、選択されたインデックスを返す (インタラクティブ版) -/
def selectOption {m : Type → Type} [Monad m] [TerminalEnv m] (prompt : String) (options : List String) : m (Option Nat) := do
  let indexedOptions := options.mapIdx (fun i o => (o, i))
  interactiveSelect prompt indexedOptions

/-- フラット化されたモデルリストからインタラクティブにモデルを選択する -/
def selectModelFlat {m : Type → Type} [Monad m] [TerminalEnv m] (categories : List (String × List (String × LlmInstance))) : m (Option (String × LlmInstance)) := do
  have : Inhabited (String × LlmInstance) := ⟨("", LlmInstance.remote { apiUrl := "", apiKey := "", modelName := none })⟩
  let flatOptions := categories.flatMap (fun (cat, ms) => ms.map (fun (name, llm) => (s!"[{cat}] {name}", (name, llm))))
  interactiveSelect "Select LLM Model" flatOptions

end Pakila.CLI.Prompts

