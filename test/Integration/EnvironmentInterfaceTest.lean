import Lyceum.Inference.Gemini
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.FileInjector
import Pakila.Plugins.LocalLeanTensor

open Lyceum

--TEMP_MARKER--
--TEMP_MARKER--

open Pakila

def runTest (name : String) (test : IO (Except String Unit)) : IO Unit := do
  IO.println s!"Running test: {name}..."
  match (← test) with
  | .ok _ => IO.println s!"[PASS] {name}"
  | .error e => IO.println s!"[FAIL] {name}: {e}"

/-- FileInjector: 正常系および異常系の検証 -/
def testFileInjector : IO (Except String Unit) := do
  let testFile := "test_tmp.txt"
  let testImg := "test_tmp.png"
  
  -- 1. テキストファイルの注入
  IO.FS.writeFile testFile "Hello Lean 4"
  let parts1 ← injectFileParts s!"Content: @{testFile}"
  if parts1.length != 2 then return Except.error s!"Expected 2 parts, got {parts1.length}"
  
  -- 2. バイナリファイルの注入
  let binData := [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A].toByteArray -- PNG Header
  IO.FS.writeBinFile testImg binData
  let parts2 ← injectFileParts s!"Image: @{testImg}"
  let foundImg := parts2.any (fun p => match p with | .image _ _ => true | _ => false)
  if !foundImg then return Except.error "Image part not found"

  -- 3. 存在しないファイル
  let parts3 ← injectFileParts "@non_existent_file.txt"
  match parts3 with
  | .text t :: _ => if !t.startsWith "@" then return Except.error "Should keep @ for non-existent files"
  | _ => return Except.error "Expected text part for non-existent file"

  -- クリーンアップ
  IO.FS.removeFile testFile
  IO.FS.removeFile testImg
  return Except.ok ()

/-- GGUF ヘッダ検証の物理テスト -/
def testGgufValidation : IO (Except String Unit) := do
  let validGguf := "physical_valid.gguf"
  let invalidGguf := "physical_invalid.gguf"
  
  -- 物理的に有効なGGUF v3ヘッダを生成 (Magic + Version 3)
  let validData := [0x47, 0x47, 0x55, 0x46, 0x03, 0x00, 0x00, 0x00].toByteArray
  IO.FS.writeBinFile validGguf validData
  -- 不正なヘッダ
  IO.FS.writeBinFile invalidGguf ([0x49, 0x6e, 0x76, 0x61, 0x6c, 0x69, 0x64].toByteArray)
  
  let checkHeader (p : String) : IO Bool := do
    let handle ← IO.FS.Handle.mk p .read
    let header ← handle.read 4
    let version_buf ← handle.read 4
    let isMagic := header.size == 4 && 
           header.get! 0 == 0x47 && header.get! 1 == 0x47 && 
           header.get! 2 == 0x55 && header.get! 3 == 0x46
    let isV3 := version_buf.size == 4 && version_buf.get! 0 == 0x03
    return isMagic && isV3

  if !(← checkHeader validGguf) then 
    IO.FS.removeFile validGguf
    IO.FS.removeFile invalidGguf
    return Except.error "Physical GGUF v3 was rejected"
  if (← checkHeader invalidGguf) then 
    IO.FS.removeFile validGguf
    IO.FS.removeFile invalidGguf
    return Except.error "Invalid GGUF was accepted"

  IO.FS.removeFile validGguf
  IO.FS.removeFile invalidGguf
  return Except.ok ()

/-- Base64 外部コマンド連携のテスト -/
def testBase64InterOp : IO (Except String Unit) := do
  let original := "Lean 4 Multimodal".toUTF8
  let encoded ← toBase64 original
  let decoded ← fromBase64 encoded
  if decoded != original then 
    return Except.error s!"Base64 mismatch."
  return Except.ok ()

def main : IO Unit := do
  IO.println "=== Pakila Environment Interface Test Suite ==="
  runTest "FileInjector" testFileInjector
  runTest "GgufValidation" testGgufValidation
  runTest "Base64InterOp" testBase64InterOp
