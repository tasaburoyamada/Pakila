import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Environment
import Pakila.Plugins.FFI
import Pakila.Util.String

open Lyceum
open Pakila

namespace Pakila

/-- システムリソース情報 -/
structure SystemInfo where
  os : String := "Unknown OS"
  cpuUsage : Float := 0.0
  memoryUsage : Float := 0.0
deriving Repr, BEq, Inhabited

/-- /proc/meminfo から単一パス（1回走査）で MemTotal と MemAvailable を抽出する (Linux用) -/
def getMemoryUsagePure : IO Float := do
  try
    let content ← TerminalEnv.readFile "/proc/meminfo"
    let lines := content.splitOn "\n"
    let mut total := 0.0
    let mut avail := 0.0

    for line in lines do
      if line.startsWith "MemTotal:" then
        let parts := line.splitOn ":" |>.getD 1 "" |>.trimAscii.toString.splitOn " " |>.filter (!·.isEmpty)
        total := parts.head?.map stringToFloat |>.getD 0.0
      else if line.startsWith "MemAvailable:" then
        let parts := line.splitOn ":" |>.getD 1 "" |>.trimAscii.toString.splitOn " " |>.filter (!·.isEmpty)
        avail := parts.head?.map stringToFloat |>.getD 0.0

    if total == 0.0 then return 0.0
    return (total - avail) / total
  catch _ => return 0.0

/-- /proc/stat から CPU 使用率を計算する (Linux用) -/
def getCpuUsagePure : IO Float := do
  try
    let content ← TerminalEnv.readFile "/proc/stat"
    let lines := content.splitOn "\n"
    match lines.head? with
    | some firstLine =>
        let parts := firstLine.splitOn " " |>.filter (!·.isEmpty) |>.tail
        if parts.length < 4 then return 0.0
        let idle := stringToFloat parts[3]!
        let total := parts.foldl (fun acc s => acc + stringToFloat s) 0.0
        if total == 0.0 then return 0.0
        return (total - idle) / total
    | none => return 0.0
  catch _ => return 0.0

/-- システム情報を取得する (Pure Lean Implementation) -/
def getSystemInfo : IO SystemInfo := do
  let path : System.FilePath := { toString := "/proc/stat" }
  let isLinux ← path.pathExists
  if isLinux then
    let cpu ← getCpuUsagePure
    let mem ← getMemoryUsagePure
    return { os := "Linux", cpuUsage := cpu, memoryUsage := mem }
  else
    return { os := "Unknown", cpuUsage := 0.0, memoryUsage := 0.0 }

/-- ターミナル幅を取得する -/
def getTerminalWidth : IO Nat := do
  let (w, _) ← Pakila.Plugins.FFI.getTerminalSizeNative ()
  return w

/-- システム情報を整形して文字列にする -/
def formatSystemInfo (info : SystemInfo) : String :=
  s!"OS: {info.os}\nCPU Usage: {info.cpuUsage * 100.0}%\nMemory Usage: {info.memoryUsage * 100.0}%"

end Pakila
