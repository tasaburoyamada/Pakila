import Pakila.Core.Interface
import Pakila.Core.State
import Pakila.CLI.Theme
import Init.System.IO

namespace Pakila.Test

/-- モックターミナルの状態定義 -/
structure MockTerminalState where
  inputs : List String
  outputs : List String
  files : List (String × String)
  currentState : Option InterpreterState := none

/-- モック環境のモナド定義 -/
abbrev MockM := StateT MockTerminalState IO

instance : TerminalEnv MockM where
  print s := modify (fun st => { st with outputs := st.outputs ++ [s] })
  println s := modify (fun st => { st with outputs := st.outputs ++ [s ++ "\n"] })
  readLine := do
    let st ← get
    match st.inputs with
    | [] => pure ""
    | h :: t => 
        set { st with inputs := t }
        pure h
  enableRawMode := pure (.ok true)
  disableRawMode := pure ()
  isRawMode := pure false
  getTerminalSize := pure (80, 24)
  readChar := pure 0
  spawnBrowser _ := pure true
  loadHistory _ := pure []
  appendHistory _ _ := pure ()
  readFile path := do
    let st ← get
    match st.files.find? (fun (p, _) => p == path.toString) with
    | some (_, c) => pure c
    | none => pure ""
  readBinFile _ := pure ByteArray.empty
  writeFile path content := modify (fun st => { st with files := (path.toString, content) :: st.files.filter (fun (p, _) => p != path.toString) })
  createDirAll _ := pure ()
  rename _ _ := pure ()
  removeFile _ := pure ()
  pathExists _ := pure true
  writeBinFile _ _ := pure ()
  isDir _ := pure false
  readDir _ := pure []
  getFileName _ := pure ""
  spawnProcess _ := pure (.error "spawnProcess not supported in MockTerminal")
  getEnv _ := pure none
  getCurrentDir := pure (System.FilePath.mk ".")
  runProcess _ := pure (.ok { exitCode := 0, stdout := "", stderr := "" })
  renderUserTurn msg := modify (fun st => { st with outputs := st.outputs ++ [msg ++ "\n"] })

end Pakila.Test
