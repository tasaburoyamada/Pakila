import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference
import Pakila.Plugins.Bash

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

open Pakila

def runTest (name : String) (test : IO (Except String Unit)) : IO Unit := do
  IO.println s!"Running test: {name}..."
  match (← test) with
  | .ok _ => IO.println s!"[PASS] {name}"
  | .error e => IO.println s!"[FAIL] {name}: {e}"

/-- BashEngine: タイムアウトの物理検証 -/
def testBashTimeout : IO (Except String Unit) := do
  let engine : BashEngine := { cwd := ".", env := [], timeoutMs := 1000 }
  
  -- 2秒間スリープするコマンド（タイムアウトするはず）
  let cmd := "sleep 2"
  match (← ExecutionEngine.execute engine cmd "bash") with
  | .error (.ExecutionError msg) => 
      if msg.contains "timed out" then
        return Except.ok ()
      else
        return Except.error s!"Unexpected error message: {msg}"
  | .ok out => return Except.error s!"Command should have timed out, but succeeded with: {out}"
  | .error e => return Except.error s!"Unexpected error type: {repr e}"

/-- LlmClient: curl 異常終了の伝播テスト -/
def testCurlFailure : IO (Except String Unit) := do
  -- 無効なURLを指定して curl を失敗させる
  let client : LlmClient := { apiUrl := "https://non-existent-domain.pakila", apiKey := "key" }
  
  match (← LlmBackend.listModels client) with
  | .error (.LlmError msg) => 
      if msg.contains "curl" then return Except.ok ()
      else return Except.error s!"Error message should mention curl: {msg}"
  | .ok res => return Except.error s!"Request should have failed, but got models: {res}"
  | .error e => return Except.error s!"Unexpected error type: {repr e}"

/-- 大規模バイナリデータのパイプラインテスト -/
def testLargeBinaryPipe : IO (Except String Unit) := do
  -- 100KB のランダムデータ (Lean のループが遅いためサイズを調整)
  let mut dataList := []
  for i in [0:100000] do
    dataList := UInt8.ofNat (i % 256) :: dataList
  let largeData := dataList.toByteArray
  
  -- base64 変換の耐久テスト
  let encoded ← toBase64 largeData
  let decoded ← fromBase64 encoded
  
  if decoded.size != largeData.size then
    return Except.error s!"Size mismatch. Expected {largeData.size}, got {decoded.size}"
  
  return Except.ok ()

def main : IO Unit := do
  IO.println "=== Pakila Robustness & Resource Test Suite ==="
  runTest "BashTimeout" testBashTimeout
  runTest "CurlFailure" testCurlFailure
  runTest "LargeBinaryPipe" testLargeBinaryPipe
