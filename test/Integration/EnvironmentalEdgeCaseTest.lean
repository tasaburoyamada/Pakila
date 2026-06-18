import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.FileInjector
import Pakila.Plugins.Bash

open Lyceum

--TEMP_MARKER--

open Pakila

def runTest (name : String) (test : IO (Except String Unit)) : IO Unit := do
  IO.println s!"Running test: {name}..."
  try
    match (← test) with
    | .ok _ => IO.println s!"[PASS] {name}"
    | .error e => IO.println s!"[FAIL] {name}: {e}"
  catch e =>
    IO.println s!"[FATAL CRASH] {name}: {e}"

/-- BashEngine: クォーティングと特殊文字の処理テスト -/
def testShellQuoting : IO (Except String Unit) := do
  let engine : BashEngine := { cwd := ".", env := [], timeoutMs := 5000 }
  
  -- 複雑な引用符を含むコマンド
  let cmd := "echo 'It'\"'\"'s a complex \"string\" with $PATH and `id`'"
  match (← ExecutionEngine.execute engine cmd "bash") with
  | .ok out => 
      if out.contains "It's a complex \"string\"" then return Except.ok ()
      else return Except.error s!"Output mismatch or quoting failed: {out}"
  | .error e => return Except.error s!"Execution failed: {repr e}"

/-- FileInjector: 権限のないファイルへのアクセス -/
def testFilePermissions : IO (Except String Unit) := do
  let testFile := "restricted.txt"
  -- 前回の残骸がある場合に備えて物理的に削除を試みる
  let _ ← IO.Process.spawn { cmd := "rm", args := #["-f", testFile] } >>= (·.wait)
  
  IO.FS.writeFile testFile "Secret"
  
  -- 権限を 000 に変更
  let _ ← IO.Process.run { cmd := "chmod", args := #["000", testFile] }
  
  let res ← try 
    let p ← injectFileParts s!"@{testFile}"
    pure (Except.ok p)
  catch e => 
    pure (Except.error (toString e))
  
  match res with
  | Except.ok parts =>
      -- 内容が Secret を含んでいないことを確認（読み取り失敗により元の文字列が維持されているはず）
      let hasSecret := parts.any (fun p => match p with | .text t => t.contains "Secret" | _ => false)
      let _ ← IO.Process.run { cmd := "chmod", args := #["644", testFile] }
      if hasSecret then return Except.error "Should not have read restricted file"
      else return Except.ok ()
  | Except.error _ =>
      let _ ← IO.Process.run { cmd := "chmod", args := #["644", testFile] }
      return Except.ok ()

/-- BashEngine: カレントディレクトリが存在しない場合のエラーハンドリング -/
def testMissingCwd : IO (Except String Unit) := do
  let engine : BashEngine := { cwd := "./non_existent_dir_pakila", env := [], timeoutMs := 5000 }
  match (← ExecutionEngine.execute engine "ls" "bash") with
  | .error _ => return Except.ok ()
  | .ok out => 
      -- エラーメッセージまたは終了コードが含まれていれば合格
      if out.contains "Exit Code" || out.isEmpty then return Except.ok ()
      else return Except.error s!"Should have failed with missing cwd, but got: {out}"

/-- BashEngine: 巨大な出力に対するリミッターの検証 -/
def testStdoutLimit : IO (Except String Unit) := do
  let engine : BashEngine := { cwd := ".", env := [], timeoutMs := 5000 }
  
  -- 1.1MB の出力を生成するコマンド (リミッターは 1MB)
  let cmd := "head -c 1100000 /dev/zero | tr '\\0' 'A'"
  match (← ExecutionEngine.execute engine cmd "bash") with
  | .ok out => 
      if out.contains "Output truncated" then return Except.ok ()
      else return Except.error s!"Output was not truncated as expected. Length: {out.length}"
  | .error e => return Except.error s!"Execution failed: {repr e}"

/-- FileInjector: 循環シンボリックリンクの回避テスト -/
def testSymlinkLoop : IO (Except String Unit) := do
  let linkA := "loop_a"
  let linkB := "loop_b"
  
  -- 循環リンクの作成: A -> B, B -> A
  let _ ← IO.Process.spawn { cmd := "ln", args := #["-sf", linkB, linkA] } >>= (·.wait)
  let _ ← IO.Process.spawn { cmd := "ln", args := #["-sf", linkA, linkB] } >>= (·.wait)
  
  let parts ← injectFileParts s!"@{linkA}"
  
  match parts with
  | .text t :: _ => 
      let _ ← IO.Process.spawn { cmd := "rm", args := #["-f", linkA, linkB] } >>= (·.wait)
      if t == s!"@{linkA}" then return Except.ok ()
      else return Except.error s!"Symlink loop was not handled correctly: {t}"
  | _ =>
      let _ ← IO.Process.spawn { cmd := "rm", args := #["-f", linkA, linkB] } >>= (·.wait)
      return Except.ok ()

def main : IO Unit := do
  IO.println "=== Pakila Advanced Environmental Edge Case Test Suite ==="
  runTest "ShellQuoting" testShellQuoting
  runTest "FilePermissions" testFilePermissions
  runTest "MissingCwd" testMissingCwd
  runTest "StdoutLimit" testStdoutLimit
  runTest "SymlinkLoop" testSymlinkLoop
