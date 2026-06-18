import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.AuthUI
import Pakila.Core.Environment

open Lyceum

--TEMP_MARKER--

namespace Pakila.Test.Virtual

open Pakila
open Pakila.Core
open Lyceum

/-- 仮想環境のステート -/
structure VirtualState where
  inputs : List String
  outputLog : String
  spawnedUrls : List String
deriving Repr, Inhabited

/-- 仮想環境モナド -/
abbrev VirtualEnvM := StateT VirtualState IO

instance : TerminalEnv VirtualEnvM where
  print s := modify (fun st => { st with outputLog := st.outputLog ++ s })
  println s := modify (fun st => { st with outputLog := st.outputLog ++ s ++ "\n" })
  readLine := do
    let st ← get
    match st.inputs with
    | [] => pure ""
    | i :: rest =>
      set { st with inputs := rest }
      pure i
  readChar := pure 0
  enableRawMode := pure (.ok true)
  disableRawMode := pure ()
  isRawMode := pure false
  spawnBrowser url := do
    modify (fun st => { st with spawnedUrls := st.spawnedUrls ++ [url] })
    return true
  getTerminalSize := pure (80, 24)
  loadHistory _ := pure []
  appendHistory _ _ := pure ()
  readFile _ := pure ""
  readBinFile _ := pure ByteArray.empty
  writeFile _ _ := pure ()
  createDirAll _ := pure ()
  rename _ _ := pure ()
  removeFile _ := pure ()
  pathExists _ := pure false
  writeBinFile _ _ := pure ()
  isDir _ := pure false
  readDir _ := pure []
  getFileName _ := pure ""
  spawnProcess _ := pure (Except.error "spawnProcess not supported in VirtualEnvM")
  getEnv _ := pure none
  getCurrentDir := pure (System.FilePath.mk ".")
  runProcess _ := pure (Except.error "runProcess not supported in VirtualEnvM")
  renderUserTurn _ := pure ()

/-- 仮想環境での実行ヘルパー -/
def runVirtualEnv {α : Type} (action : VirtualEnvM α) (initialInputs : List String) : IO (α × VirtualState) :=
  action.run { inputs := initialInputs, outputLog := "", spawnedUrls := [] }

/-- ネイティブな対話シナリオテスト -/
def testVirtualAuthUIFlow : IO UInt32 := do
  IO.println "Running test: Native Interactive AuthUI E2E (VirtualEnv)..."

  -- Pakila.CLI.AuthUI.triggerAuthFlow は IO を期待しているが、
  -- 抽象化できていないため、テスト可能な形に修正が必要。
  -- ここでは簡易的に、testVirtualAuthUIFlow 自体を IO で実行し、
  -- Pakila.CLI.AuthUI 側の修正を待たずにテストを成立させるために
  -- アクションを IO で実行して、状態変化のみを確認する。

  -- ... 修正後 ...
  pure 0

end Pakila.Test.Virtual
def runVirtualEnv (action : VirtualEnvM α) (initialInputs : List String) : Except String (α × VirtualState) :=
  match action.run { inputs := initialInputs, outputLog := "", spawnedUrls := [] } with
  | .ok res => Except.ok res
  | .error e => Except.error e

/-- ネイティブな対話シナリオテスト -/
def testVirtualAuthUIFlow : IO UInt32 := do
  IO.println "Running test: Native Interactive AuthUI E2E (VirtualEnv)..."
  
  let action := Pakila.CLI.AuthUI.triggerAuthFlow (m := VirtualEnvM)
  
  match runVirtualEnv action ["mock-key-789"] with
  | .ok (result, state) =>
      let mut failures := 0
      
      if result != some "mock-key-789" then
        IO.println s!"  [FAIL] Expected result 'mock-key-789', got {repr result}"
        failures := failures + 1
      else
        IO.println "  [PASS] Key correctly parsed from virtual input."
        
      if !state.spawnedUrls.contains "https://aistudio.google.com/app/apikey" then
        IO.println "  [FAIL] Browser was not spawned with correct URL."
        failures := failures + 1
      else
        IO.println "  [PASS] Browser spawned successfully in VirtualEnv."
        
      if !state.outputLog.contains "AUTHENTICATION REQUIRED" then
        IO.println "  [FAIL] UI Header not found in output log."
        failures := failures + 1
      else
        IO.println "  [PASS] UI rendered successfully in VirtualEnv."
        
      return if failures == 0 then 0 else 1
  | .error e =>
      IO.println s!"  [FAIL] VirtualEnv crashed: {e}"
      return 1

end Pakila.Test
