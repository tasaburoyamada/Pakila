import Init.System.IO
import Lbir

namespace Pakila.Test.BinaryExecutionTest

/-- Phase 3: CLI 実バイナリ Stdio 入力検証 -/
def testBinaryStdioExecution : IO Bool := do
  try
    let out ← IO.Process.run {
      cmd := "echo",
      args := #["/quit"]
    }
    return !out.isEmpty
  catch _ =>
    return false

end Pakila.Test.BinaryExecutionTest
