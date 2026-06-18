import Pakila.Core.Interface
import Pakila.Core.Types

namespace Pakila.Test

/-- テスト用のモック TerminalEnv -/
structure MockTerminalEnv where
  output : IO.Ref String
deriving Inhabited

instance : TerminalEnv where
  print text := do
    let ref ← IO.mkRef ""
    ref.modify (· ++ text)
  println text := do
    let ref ← IO.mkRef ""
    ref.modify (· ++ text ++ "\n")
  readLine := pure "mock_input"
  readChar := pure 0
  enableRawMode := pure (.ok true)
  disableRawMode := pure ()
  isRawMode := pure false
  spawnBrowser _ := pure true
  getTerminalSize := pure (80, 24)
  loadHistory _ := pure []
  appendHistory _ _ := pure ()
  readFile _ := pure "mock_file_content"
  readBinFile _ := pure ByteArray.empty
  writeFile _ _ := pure ()
  createDirAll _ := pure ()
  rename _ _ := pure ()
  removeFile _ := pure ()
  pathExists _ := pure true
  writeBinFile _ _ := pure ()
  isDir _ := pure false
  readDir _ := pure []
  getFileName _ := pure "mock_file"
  spawnProcess _ _ := pure (.ok default)
  getEnv _ := pure none
  getCurrentDir := pure System.FilePath.mk "."
  runProcess _ := pure (.ok { exitCode := 0, stdout := "mock_output", stderr := "" })

end Pakila.Test
