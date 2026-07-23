import test.Native.QuantizationTest
import test.Integration.ComprehensiveTest

import test.Integration.UniversalRobustnessTest
import test.Integration.AdversarialBoundaryTest
import test.Integration.LongTermStateTest
import test.Integration.AuthTest
import test.Integration.PhysicalAuthTest
import test.E2E.VirtualEnvTest
import test.Base64Test
import test.SysInfoTest
import test.BlackboxTraceTest
import test.BinaryExecutionTest
import Pakila.Test.CliTest

open ComprehensiveTests
open Base64Test
open SysInfoTest
open Pakila.Test
open Pakila.Test.Native

def main : IO UInt32 := do
  IO.println "=================================================="
  IO.println "  Pakila Hybrid Verification Test Suite Running   "
  IO.println "=================================================="

  -- Phase 1: Nomos Protocol & Blackbox State Trace
  IO.println "\n[Phase 1] Nomos Blackbox Trace & State Laws..."
  let bbTrace ← Pakila.Test.BlackboxTraceTest.testMachineBlackboxTrace
  if bbTrace then
    IO.println "  [PASS] Nomos Agent Machine Trace Validation"
  else
    IO.eprintln "  [FAIL] Nomos Machine Trace Mismatch"
    return 1

  -- CLI E2E Tests
  Pakila.Test.runAllTests
  
  -- Native Tests & Auth Config Test
  let resN1 ← testNativeQ80DotProduct
  if resN1 != 0 then return resN1

  let res0 ← testConfigAuthParsing
  if res0 != 0 then return res0

  let res01 ← runPhysicalAuthTest
  if res01 != 0 then return res01


  -- Phase 2: Boundary Resilience Tests
  IO.println "\n[Phase 2] Boundary Resilience & Base64/SysInfo..."
  testBase64
  testSysInfo

  let res2 ← testComprehensiveSuite
  if res2 != 0 then return res2

  let res3 ← runUniversalRobustnessTests
  if res3 != 0 then return res3

  let res4 ← runAdversarialBoundaryTests
  if res4 != 0 then return res4

  let res6 ← runLongTermStateTests
  if res6 != 0 then return res6

  -- Phase 3: Physical Binary Execution Test
  IO.println "\n[Phase 3] Physical Binary Execution & Stdio Pipeline..."
  let binRes ← Pakila.Test.BinaryExecutionTest.testBinaryStdioExecution
  if binRes then
    IO.println "  [PASS] Stdio Pipeline & Physical Binary Test"
  else
    IO.eprintln "  [FAIL] Physical Binary Test Failed"
    return 1
  
  IO.println "\n=================================================="
  IO.println "  ALL PAKILA HYBRID TEST SUITES PASSED (100%)    "
  IO.println "=================================================="
  return 0

