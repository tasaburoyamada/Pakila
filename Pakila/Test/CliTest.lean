import Nomos.MockTerminal
import Pakila.CLI.SlashCommands
import Pakila.CLI.Renderer
import Pakila.Core.Interface

namespace Pakila.Test
open Pakila.CLI
open Nomos.Mock

/-- テストケース構造体 -/
structure TestCase where
  name : String
  run : MockM Bool

/-- テストランナー -/
def runTest (t : TestCase) : IO Bool := do
  let initialState : MockTerminalState := { inputs := [], outputs := [] }
  let (result, _) ← t.run.run initialState
  if result then
    IO.println s!"[PASS] {t.name}"
    pure true
  else
    IO.println s!"[FAIL] {t.name}"
    pure false

/-- テストケース一覧 -/
def testCases : List TestCase := [
    { name := "TEST_E2E_008: Slash Commands Parsing", run := do
        let inputs := ["/model", "/rewind", "/config", "/memory", "/help", "/clear", "/reset", "/exit", "/quit"]
        for i in inputs do
          match parseSlashCommand i with
          | none => return false
          | some c => if c.cmd.name != i.drop 1 then return false
        return true },
    { name := "TEST_E2E_009: Invalid Slash Command", run := do
        return (parseSlashCommand "/foobar").isNone },

    { name := "TEST_E2E_010: Model Command Args", run := do
        match parseSlashCommand "/model gemma-4b" with
        | some c => return (c.args == ["gemma-4b"])
        | none => return false },
    { name := "TEST_E2E_014: NoticeBox Rendering", run := do
        let notice := renderNoticeBox "Integration Test"
        return (notice.contains "Integration Test") }
  ]

/-- テスト一覧の実行 -/
def runAllTests : IO Unit := do
  let results ← testCases.mapM runTest
  if results.all (· == true) then
    IO.println "All E2E tests passed."
  else
    IO.println "Some tests failed."
    IO.Process.exit 1

end Pakila.Test
