import Pakila.Core.State
import Pakila.Core.Dispatcher
import Pakila.MainLoop
import Pakila.Core.Machine
import Pakila.Plugins.Dispatcher
import Pakila.Governance.Vlog

open Pakila
open Pakila.Protocol

def main (args : List String) : IO Unit := do
  if args.contains "--help" || args.contains "-h" then
    IO.println "Pakila v0.43.0
Usage: pakila [--help] [--test <input> ...]"
    return

  -- 1. 初期状態の構築 (本来は設定からロード)
  let initialState : InterpreterState := {
    history := [],
    vlogState := [],
    activeLlm := default,
    activeModelName := "base",
    configDir := "."
  }

  -- 2. Dispatcher の構築
  let dispatcher : Dispatcher := {
    bashEngine := { cwd := ".", env := [] },
    sandboxEngine := { cwd := ".", env := [], level := .Low, timeoutMs := 10000 },
    useSandbox := false,
    resManager := default,
    wasmPlugins := []
  }

  if args.contains "--test" then
    -- 非対話型テストモード
    let testInputs := args.drop 1 -- '--test' を除いた残りを入力とする
    -- If no test inputs are provided, default to a simple /quit to ensure termination
    if testInputs.isEmpty then
      runTestLoop initialState dispatcher ["/quit"]
    else
      runTestLoop initialState dispatcher testInputs
    return
  
  -- 3. メインループの起動
  IO.println "Pakila v0.43.0 initialized (Logic-Physical Separated)."
  mainLoop initialState dispatcher
