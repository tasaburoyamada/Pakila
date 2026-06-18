import Lean
import Init.System.IO

namespace Pakila.Test.Binary

/-- 実際の Pakila バイナリを起動し、入出力を検証する -/
def runBinaryTest : IO Unit := do
  let pakilaPath := System.FilePath.mk "./.lake/build/bin/pakila"
  if !(← pakilaPath.pathExists) then
    IO.println "[FAIL] Pakila binary not found at ./.lake/build/bin/pakila"
    IO.Process.exit 1

  -- 入力をシミュレートして実行
  -- /model 切り替えをテスト
  let args := #[] -- インタラクティブモードで起動
  let process ← IO.Process.spawn {
    cmd := pakilaPath.toString,
    args := args,
    stdin := .piped,
    stdout := .piped,
    stderr := .piped
  }

  -- 入力を送信
  let stdin := process.stdin
  stdin.putStrLn "/model gemma-4b"
  stdin.putStrLn "/exit"
  stdin.flush

  -- 出力をキャプチャ
  let stdout ← process.stdout.readToEnd
  let stderr ← process.stderr.readToEnd
  let exitCode ← process.wait

  -- 検証
  if stdout.contains "Model switched to" then
    IO.println "[PASS] /model command executed and verified in binary."
  else
    IO.println s!"[FAIL] Output did not contain expected model switch message. Output: {stdout}"
    IO.println s!"[Stderr]: {stderr}"
    IO.Process.exit 1

  if exitCode == 0 then
    IO.println "[PASS] Binary exited normally."
  else
    IO.println s!"[FAIL] Binary exited with code: {exitCode}"
    IO.Process.exit 1

end Pakila.Test.Binary

def main : IO Unit := Pakila.Test.Binary.runBinaryTest
EOF
