import Lake
open Lake DSL

package «pakila» where

lean_lib «Pakila» where
  srcDir := "."

lean_lib «test» where
  srcDir := "."

@[default_target]
lean_exe «pakila» where
  root := `Main
  moreLinkArgs := #["-O3", "-L", "./deps/wasmtime/lib", "-lwasmtime", "-Wl,-rpath,$ORIGIN/../../../deps/wasmtime/lib"]

require LeanTensor from "../../engine/LeanTensor"
require nomos from "../nomos"
require lyceum from "../Lyceum"
require batteries from "../../apps/std4_fork"

extern_lib «pakila_native_kernels» (pkg : NPackage _package.name) := do
  let name := nameToStaticLib "pakila_native_kernels"
  let src ← inputTextFile (pkg.dir / "src" / "native" / "kernels.c")
  let wasmtimeInclude := pkg.dir / "deps" / "wasmtime" / "include"
  let ffiO ← buildO "kernels.o" src #[
    "-I", (← getLeanIncludeDir).toString,
    "-I", wasmtimeInclude.toString,
    "-fPIC", "-O3"
  ]
  buildStaticLib (pkg.buildDir / "lib" / name) #[ffiO]

@[test_driver]
lean_exe «test_driver» where
  root := `test.TestAll
  moreLinkArgs := #["-O3", "-L", "./deps/wasmtime/lib", "-lwasmtime", "-Wl,-rpath,$ORIGIN/../../../deps/wasmtime/lib"]

lean_exe «test_machine» where
  root := `test.Core.MachineTest

lean_exe «test_engine_direct» where
  root := `test.E2E.DirectEngineTest

def runAcceptanceTest : IO UInt32 := do
  let out ← IO.Process.spawn { cmd := "./test/E2E/scenario_runner.sh" }
  out.wait

script acceptance_test do
  runAcceptanceTest


lean_exe «test_embedding» where
  root := `test.test_native_embedding

lean_exe «test_rag» where
  root := `test.test_rag_integration

lean_exe «smoke_test» where
  root := `test.SmokeTest
  moreLinkArgs := #["-O3", "-L", "./deps/wasmtime/lib", "-lwasmtime", "-Wl,-rpath,$ORIGIN/../../../deps/wasmtime/lib"]

lean_exe «test_portability» where
  root := `test.PortabilityTest

lean_exe «test_sandbox_gaps» where
  root := `test.SandboxGapsTest

lean_exe «test_jp_tokenizer» where
  root := `test.JapaneseTokenizerTest

lean_exe «test_rag_gaps» where
  root := `test.RagGapsTest

lean_exe «test_mainloop_gaps» where
  root := `test.MainLoopGapsTest

lean_exe «test_ui_interactive» where
  root := `test.UiInteractiveTest
  moreLinkArgs := #["-O3", "-L", "./deps/wasmtime/lib", "-lwasmtime", "-Wl,-rpath,$ORIGIN/../../../deps/wasmtime/lib"]
