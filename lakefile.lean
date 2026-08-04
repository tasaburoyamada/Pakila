import Lake
open Lake DSL

package «pakila» where

lean_lib «Pakila» where
  srcDir := "src"

lean_lib «test» where
  srcDir := "."

@[default_target]
lean_exe «pakila» where
  root := `Main
  moreLinkArgs := #["-O3", "-L", "./deps/wasmtime/lib", "-lwasmtime", "-Wl,-rpath,$ORIGIN/../../../deps/wasmtime/lib"]

require LeanTensor from "../LeanTensor"
require nomos from "../nomos"
require lyceum from "../Lyceum"
require Lbir from "../lbir"


extern_lib «pakila_native_kernels» (pkg : NPackage _package.name) := do
  let name := nameToStaticLib "pakila_native_kernels"
  let src ← inputTextFile (pkg.dir / "src" / "native" / "kernels.c")
  let wasmtimeInclude := pkg.dir / "deps" / "wasmtime" / "include"
  let ffiO ← buildO (pkg.buildDir / "ir" / "kernels.o") src #[
    "-I", (← getLeanIncludeDir).toString,
    "-I", wasmtimeInclude.toString,
    "-fPIC", "-O3"
  ]
  buildStaticLib (pkg.buildDir / "lib" / name) #[ffiO]

@[test_driver]
lean_exe «test_driver» where
  root := `test.TestAll
  moreLinkArgs := #["-O3", "-L", "./deps/wasmtime/lib", "-lwasmtime", "-Wl,-rpath,$ORIGIN/../../../deps/wasmtime/lib"]

def runAcceptanceTest : IO UInt32 := do
  let out ← IO.Process.spawn { cmd := "./test/E2E/scenario_runner.sh" }
  out.wait

script acceptance_test do
  runAcceptanceTest


