import test.Native.QuantizationTest
import test.Native.LocalFirstTest
import test.Integration.ComprehensiveTest
import test.Integration.UniversalRobustnessTest
import test.Integration.AdversarialBoundaryTest
import test.Integration.LongTermStateTest
import test.Integration.AuthTest
import test.Integration.PhysicalAuthTest
import test.E2E.VirtualEnvTest
import test.Base64Test
import test.SysInfoTest
import Pakila.Test.CliTest

open ComprehensiveTests
open Base64Test
open SysInfoTest
open Pakila.Test
open Pakila.Test.Native

def main : IO UInt32 := do
  IO.println "=== Pakila 100% Pure Lean 4 Master Test Suite ==="

  -- CLI E2E Tests
  Pakila.Test.runAllTests
  
  -- -1. Native Native Test
  let resN1 ← testNativeQ80DotProduct
  if resN1 != 0 then return resN1

  let resN2 ← testLocalFirstDispatch
  if resN2 != 0 then return resN2

  let resN3 ← testLocalNativeInference
  if resN3 != 0 then return resN3

  -- 0. Auth Config Test
  let res0 ← testConfigAuthParsing
  if res0 != 0 then return res0

  -- 0.1 Physical Auth Test
  let res01 ← runPhysicalAuthTest
  if res01 != 0 then return res01

  -- 0.2 Virtual Env Auth UI Test
  let res02 ← testVirtualAuthUIFlow
  if res02 != 0 then return res02

  -- 1. Base64 Purity Test
  testBase64
  
  -- 2. SysInfo Purity Test
  testSysInfo

  -- 3. Comprehensive Integration
  let res2 ← testComprehensiveSuite
  if res2 != 0 then return res2

  -- 4. Robustness
  let res3 ← runUniversalRobustnessTests
  if res3 != 0 then return res3

  let res4 ← runAdversarialBoundaryTests
  if res4 != 0 then return res4

  let res6 ← runLongTermStateTests
  if res6 != 0 then return res6
  
  IO.println "========================================"
  IO.println "  ALL PURE LEAN TEST SUITES PASSED      "
  IO.println "========================================"
  return 0
