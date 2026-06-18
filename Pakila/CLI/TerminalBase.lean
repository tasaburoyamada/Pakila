import Pakila.Core.Environment

namespace Pakila.CLI.TerminalBase

/-- ANSIエスケープシーケンスの読み込み -/
def readEscape {m : Type → Type} [Monad m] [TerminalEnv m] : m (Option String) := do
  let b1 ← TerminalEnv.readChar
  if b1 == 0 then return none -- EOF
  if b1 == 91 then -- '['
    let b2 ← TerminalEnv.readChar
    if b2 == 0 then return none
    match b2 with
    | 65 => return some "UP"
    | 66 => return some "DOWN"
    | 67 => return some "RIGHT"
    | 68 => return some "LEFT"
    | _ => return none
  return none

/-- 
汎用的なインタラクティブ・セレクター。
矢印キーで選択し、Enter で決定、Esc でキャンセル。
-/
def interactiveSelect {m : Type → Type} [Monad m] [TerminalEnv m] [Inhabited α] (title : String) (options : List (String × α)) : m (Option α) := do
  if options.isEmpty then return none
  
  let mut selectedIdx := 0
  let mut loop := true
  let mut finalChoice := none

  let redrawMenu (idx : Nat) : m Unit := do
    TerminalEnv.print s!"\r\x1b[K\x1b[1;34m--- {title} ---\x1b[0m\n\r"
    for i in [0:options.length] do
      let (display, _) := options[i]!
      if i == idx then
        TerminalEnv.print s!"\x1b[K \x1b[1;32m❯ {display}\x1b[0m\n\r"
      else
        TerminalEnv.print s!"\x1b[K   {display}\n\r"
    TerminalEnv.print s!"\x1b[K\x1b[38;5;242m(Use ↑/↓ to navigate, Enter to select, Esc to cancel)\x1b[0m"
    TerminalEnv.print s!"\x1b[{options.length + 1}A"

  -- すでにRAWモードなら変更しない
  let actualChanged ← match (← TerminalEnv.enableRawMode) with
    | .ok b => pure b
    | .error _ => pure false

  redrawMenu selectedIdx

  while loop do
    let b ← TerminalEnv.readChar
    match b with
    | 0 => -- EOF
        loop := false
    | 13 => -- Enter
        if h : selectedIdx < options.length then
          finalChoice := some options[selectedIdx].2
        loop := false
    | 27 => -- Escape or Arrow
        if let some esc ← readEscape then
          match esc with
          | "UP" =>
              selectedIdx := if selectedIdx > 0 then selectedIdx - 1 else options.length - 1
              redrawMenu selectedIdx
          | "DOWN" =>
              selectedIdx := (selectedIdx + 1) % options.length
              redrawMenu selectedIdx
          | _ => pure ()
        else
          loop := false 
    | 3 | 4 => -- Ctrl+C/D
        loop := false
    | _ => pure ()

  -- メニューをクリア
  TerminalEnv.print s!"\r\x1b[K"
  for _ in [0:options.length + 1] do
    TerminalEnv.print "\x1b[B\x1b[K"
  TerminalEnv.print s!"\x1b[{options.length + 1}A"

  -- 自分が有効化した場合のみ無効化する（入れ子構造の維持）
  if actualChanged then TerminalEnv.disableRawMode

  return finalChoice

end Pakila.CLI.TerminalBase
