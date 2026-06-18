import Pakila.CLI.Terminal
import Pakila.CLI.Prompts
import Pakila.Core.Environment
import Lyceum.Types

open Pakila
open Pakila.CLI
open Lyceum

/-- 
テスト用のモック環境。
入力シーケンスを事前に定義し、出力をキャプチャする。
-/
structure MockState where
  input : List UInt8
  output : List String := []
  isRaw : Bool := false
  cols : Nat := 80
  lines : Nat := 24
  history : List String := []

abbrev MockM := StateT MockState IO

instance : TerminalEnv MockM where
  print s := modify (fun s' => { s' with output := s'.output ++ [s] })
  println s := modify (fun s' => { s' with output := s'.output ++ [s, "\n"] })
  readLine := do
    let s ← get
    let mut line := ""
    let mut remaining := s.input
    while !remaining.isEmpty do
      let b := remaining.head!
      remaining := remaining.tail!
      if b == 13 || b == 10 then break
      line := line.push (Char.ofNat b.toNat)
    set { s with input := remaining }
    return line
  readChar := do
    let s ← get
    match s.input with
    | [] => return 0
    | b :: rest =>
        set { s with input := rest }
        return b
  enableRawMode := do
    let s ← get
    if s.isRaw then return .ok false
    modify (fun s => { s with isRaw := true })
    return .ok true
  disableRawMode := modify (fun s => { s with isRaw := false })
  isRawMode := do
    let s ← get
    return s.isRaw
  spawnBrowser _ := return true
  getTerminalSize := do
    let s ← get
    return (s.cols, s.lines)
  loadHistory _ := do
    let s ← get
    return s.history
  appendHistory _ line := modify (fun s => { s with history := s.history ++ [line] })
  readFile _ := return ""
  readBinFile _ := return ByteArray.empty
  writeFile _ _ := return ()
  createDirAll _ := return ()
  rename _ _ := return ()

/-- 特殊キーの定義 -/
def keyEnter : List UInt8 := [13]
def keyUp    : List UInt8 := [27, 91, 65]
def keyDown  : List UInt8 := [27, 91, 66]
def keySlash : List UInt8 := [47]

def runUiTest (name : String) (inputs : List UInt8) (initialHistory : List String := []) (testFn : MockM Unit) : IO Unit := do
  IO.print s!"Running UI Test: {name}... "
  let (_, _) ← testFn.run { input := inputs, history := initialHistory }
  IO.println "DONE"

def testBasicInput : IO Unit := do
  let inputs := "hello".toList.map (fun c => c.toNat.toUInt8) ++ keyEnter
  runUiTest "Basic Input" inputs [] do
    let res ← readLineWithHistory "❯ " "."
    match res with
    | some "hello" => pure ()
    | _ => throw (IO.userError s!"Basic Input failed: got {repr res}")

def testSlashCommand : IO Unit := do
  -- "/" + Down + Enter (to pick) + Enter (to submit prompt)
  let inputs := keySlash ++ keyDown ++ keyEnter ++ keyEnter
  runUiTest "Slash Command (Select Second)" inputs [] do
    let res ← readLineWithHistory "❯ " "."
    -- availableSlashCommands[1] is /memory
    match res with
    | some "/memory" => pure ()
    | _ => throw (IO.userError s!"Slash Command failed: expected /memory, got {repr res}")

def testHistoryNavigation : IO Unit := do
  let inputs := keyUp ++ keyEnter
  runUiTest "History Navigation (UP)" inputs ["past command"] do
    let res ← readLineWithHistory "❯ " "."
    match res with
    | some "past command" => pure ()
    | _ => throw (IO.userError s!"History Navigation failed: expected 'past command', got {repr res}")

def main : IO Unit := do
  IO.println "--- Pakila UI/UX Interactive Test Suite ---"
  testBasicInput
  testSlashCommand
  testHistoryNavigation
  IO.println "--- All UI Tests Passed ---"
