import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.History
import Pakila.CLI.Theme
import Pakila.CLI.SlashCommands
import Pakila.CLI.TerminalBase
import Pakila.Core.Environment
import Pakila.Core.LlmManager
import Pakila.Plugins.FFI

open Lyceum
open Pakila
open Pakila.CLI
open Pakila.CLI.TerminalBase
open Pakila.CLI.History

namespace Pakila

deriving instance Inhabited for IO.FS.DirEntry

/-- カスタムReadLineの実装 (汎用版) -/
def readLineWithHistory {m : Type → Type} [Monad m] [TerminalEnv m] [MonadFinally m] [MonadLiftT IO m] (prompt : String) (configDir : System.FilePath) : m (Option String) := do
  let history ← loadHistory configDir
  let mut currentHistory := history.reverse
  let mut historyIdx : Option Nat := none
  let mut buffer : List Char := []
  let mut pos : Nat := 0
  let mut savedBuffer : List Char := []

  let redraw (p : String) (b : List Char) (currPos : Nat) (ghost : String) : m Unit := do
    let s := String.ofList b
    TerminalEnv.print s!"\r\x1b[K{p}{s}"
    if !ghost.isEmpty then
      TerminalEnv.print (applyColor ProfessionalColors.gray ghost)
    -- Move cursor back to current position
    let totalLen := s.length + ghost.length
    if totalLen > currPos then
      TerminalEnv.print s!"\x1b[{totalLen - currPos}D"

  -- RAWモード設定を試みる。失敗した場合は標準のreadLineにフォールバック。
  let res ← match (← TerminalEnv.enableRawMode) with
  | .error _e => do
      TerminalEnv.print prompt
      let line ← TerminalEnv.readLine
      if line.isEmpty then pure none
      else pure (some line)
  | .ok _ => do
      let mut ghostText := ""
      let updateGhost (b : List Char) : String :=
        if b.isEmpty then ""
        else
          let s := String.ofList b
          match currentHistory.find? (·.startsWith s) with
          | some h => (h.drop s.length).toString
          | none => ""

      redraw prompt buffer pos ghostText

      try
        let mut loop := true
        let mut finalRes := none
        let mut completionIdx : Option Nat := none

        while loop do
          let b ← TerminalEnv.readChar
          
          match b with
          | 0 => -- EOF
              loop := false
          | 3 => -- Ctrl+C
              TerminalEnv.print "^C\n\r"
              loop := false
              finalRes := none
          | 4 => -- Ctrl+D
              if buffer.isEmpty then
                loop := false
                finalRes := none
              else
                if pos < buffer.length then
                  buffer := buffer.take pos ++ buffer.drop (pos + 1)
                  ghostText := updateGhost buffer
                  redraw prompt buffer pos ghostText
          | 9 => -- Tab (Cycle Completion)
              let inputSoFar := String.ofList buffer
              if inputSoFar.startsWith "/" then do
                let pref := inputSoFar
                let matchedCmds := availableSlashCommands.filter (fun c => (s!"/{c.name}").startsWith pref)
                if !matchedCmds.isEmpty then
                  let idx := match completionIdx with | some i => (i + 1) % matchedCmds.length | none => 0
                  completionIdx := some idx
                  let chosen := matchedCmds.toArray[idx]!
                  buffer := chosen.template.toList
                  pos := buffer.length
                  ghostText := ""
                  redraw prompt buffer pos ghostText
              pure ()
          | 13 => -- Enter
              TerminalEnv.print "\n\r"
              loop := false
              finalRes := some (String.ofList buffer)
          | 27 => -- Escape or Arrow
              completionIdx := none
              if let some esc ← readEscape then
                match esc with
                | "UP" =>
                    let nextIdx := match historyIdx with
                      | none => if currentHistory.isEmpty then none else some 0
                      | some i => if i + 1 < currentHistory.length then some (i + 1) else some i
                    if nextIdx != historyIdx then
                      if historyIdx == none then savedBuffer := buffer
                      historyIdx := nextIdx
                      if let some i := historyIdx then
                        if h : i < currentHistory.length then
                          buffer := currentHistory[i].toList
                          pos := buffer.length
                      ghostText := ""
                      redraw prompt buffer pos ghostText
                | "DOWN" =>
                    let nextIdx := match historyIdx with
                      | none => none
                      | some 0 => none
                      | some i => some (i - 1)
                    if nextIdx != historyIdx then
                      historyIdx := nextIdx
                      match historyIdx with
                      | none => buffer := savedBuffer
                      | some i => 
                          if h : i < currentHistory.length then
                            buffer := currentHistory[i].toList
                      pos := buffer.length
                      ghostText := ""
                      redraw prompt buffer pos ghostText
                | "RIGHT" =>
                    if pos < buffer.length then
                      pos := pos + 1
                      TerminalEnv.print "\x1b[C"
                    else if !ghostText.isEmpty then
                      -- Accept ghost text
                      buffer := buffer ++ ghostText.toList
                      pos := buffer.length
                      ghostText := ""
                      redraw prompt buffer pos ghostText
                | "LEFT" =>
                    if pos > 0 then
                      pos := pos - 1
                      TerminalEnv.print "\x1b[D"
                | _ => pure ()
          | 127 | 8 => -- Backspace
              completionIdx := none
              if pos > 0 then
                buffer := buffer.take (pos - 1) ++ buffer.drop pos
                pos := pos - 1
                ghostText := updateGhost buffer
                redraw prompt buffer pos ghostText
          | _ =>
              completionIdx := none
              if b == 47 && buffer.isEmpty then -- '/' trigger at start
                let opts := availableSlashCommands.map (fun c => (s!"/{c.name} - {c.description}", c.template))
                let picked ← interactiveSelect "Select Command" opts
                match picked with
                | some cmd =>
                    buffer := cmd.toList
                    pos := buffer.length
                    ghostText := ""
                    redraw prompt buffer pos ghostText
                | none =>
                    redraw prompt buffer pos ghostText
              else if b >= 32 && b <= 126 then
                let c := Char.ofNat b.toNat
                buffer := buffer.take pos ++ [c] ++ buffer.drop pos
                pos := pos + 1
                ghostText := updateGhost buffer
                redraw prompt buffer pos ghostText
        pure finalRes
      finally
        TerminalEnv.disableRawMode

  if let some line := res then
    if !line.trimAscii.toString.isEmpty then
      appendHistory configDir line
  return res

/-- モデル選択メニューの表示 -/
def selectModelFlat {m : Type → Type} [Monad m] [TerminalEnv m] (categories : List (String × List (String × LlmInstance))) : m (Option (String × LlmInstance)) := do
  let mut flatOptions : List (String × (String × LlmInstance)) := []
  for (cat, models) in categories do
    for (name, inst) in models do
      flatOptions := flatOptions ++ [(s!"[{cat}] {name}", (name, inst))]
  
  interactiveSelect "Select Model" flatOptions

end Pakila