import Pakila.Diagnostics.SysInfo

namespace SysInfoTest

def testSysInfo : IO Unit := do
  IO.println "[Test] Pure Lean SysInfo (/proc)..."
  let info ← Pakila.getSystemInfo
  IO.println s!"Detected: {Pakila.formatSystemInfo info}"
  if info.os != "Unknown OS" then
    IO.println "[Test] SysInfo PASSED."
  else
    IO.println "[Test] SysInfo SKIPPED (Non-Linux or restricted environment)."

end SysInfoTest
