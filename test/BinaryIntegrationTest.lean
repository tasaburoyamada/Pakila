import Lean
import Init.System.IO

namespace Pakila.Test.Binary

/-- 実際の Pakila バイナリを起動し、入出力を検証する -/
def runBinaryTest : IO UInt32 := do
  -- バイナリの絶対パスを確定（CWD非依存）
  let cwd ← IO.currentDir
  let p1 := cwd / ".lake/build/bin/pakila"
  let p2 := cwd / "apps/pakila/.lake/build/bin/pakila"
  IO.println s!"[DEBUG] {p1}: {← p1.pathExists}"
  IO.println s!"[DEBUG] {p2}: {← p2.pathExists}"

  let pakilaPath := if ← p1.pathExists then p1 else p2
  if !(← pakilaPath.pathExists) then
    IO.println s!"[FAIL] Pakila binary not found at {pakilaPath}"
    return 1

  -- 隔離された一時ディレクトリを作成してCWDとする。
  -- これにより実環境の ./config.toml が読まれることを防ぐ。
  -- （App.lean は ./config.toml → ~/.config/pakila/config.toml の順で探索する）
  let tmpDir := System.FilePath.mk "/tmp/pakila_binary_test"
  IO.FS.createDirAll tmpDir

  -- テスト用 config を一時ディレクトリに配置。
  -- llmModel に実在しないモデル名を指定 → discoverCategorizedModels で見つからない
  -- → selectedModelName.isEmpty → App.run が即 return → exitcode 0
  -- ただし上記ルートを通らず runLoop に入った場合も /quit で脱出できるよう stdin に送る。
  IO.FS.writeFile (tmpDir / "config.toml")
    "llmApiKey = \"test_dummy_key\"\nllmModel = \"__no_such_model_for_test__\"\n"

  let process ← IO.Process.spawn {
    cmd := pakilaPath.toString,
    args := #[],
    cwd := some tmpDir,       -- 隔離 CWD：ここの config.toml のみ参照される
    stdin := .piped,
    stdout := .piped,
    stderr := .piped
  }

  -- フォールバック: runLoop に入った場合に備えて /quit を送る
  process.stdin.putStrLn "/quit"
  process.stdin.putStrLn "／quit"
  process.stdin.flush

  let stdout ← process.stdout.readToEnd
  let stderr ← process.stderr.readToEnd
  let exitCode ← process.wait

  if !stderr.isEmpty then
    IO.println s!"[DEBUG] pakila stderr: {stderr}"
  if exitCode != 0 then
    IO.println s!"[FAIL] pakila process exited with non-zero code: {exitCode}"
    return 1

  -- UTF-8 破壊チェック
  if stdout.contains "\uFFFD" then
    IO.println "[FAIL] UTF-8 decoding error detected (replacement character U+FFFD found)."
    return 1

  IO.println "[PASS] TEST_BIN_001: Binary launched and exited cleanly (exit code 0)."
  IO.println s!"[DEBUG] stdout length: {stdout.length} bytes"

  IO.println "[DEBUG] Binary integration tests finished successfully."
  return 0

end Pakila.Test.Binary
