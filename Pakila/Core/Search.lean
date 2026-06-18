import Pakila.Core.Interface
import Pakila.Core.Primitives
import Pakila.Protocol.Types
import Pakila.Core.Types
import Lean

open Pakila
open Pakila.Protocol

open Lyceum

namespace Pakila

/-- ネイティブな再帰検索ロジック (grep互換) -/
partial def nativeGrep [Monad m] [MonadExcept ε m] [TerminalEnv m] (pat : String) (dir : System.FilePath) : m String := do
  if !(← TerminalEnv.pathExists dir) then return ""
  if !(← TerminalEnv.isDir dir) then return ""
  let entries ← TerminalEnv.readDir dir
  let mut acc := ""
  for entryPath in entries do
    if (← TerminalEnv.isDir entryPath) then
      let res ← nativeGrep pat entryPath
      acc := acc ++ res
    else
      try
        let content ← TerminalEnv.readFile entryPath
        let lines := content.splitOn "
"
        for i in [0:lines.length] do
          let l := lines[i]!
          if l.contains pat then
            acc := acc ++ s!"{entryPath}:{i + 1}:{l}
"
      catch _ => pure ()
  return acc

/-- ネイティブな再帰探索ロジック (find/glob互換) -/
partial def nativeGlob [Monad m] [TerminalEnv m] (pat : String) (dir : System.FilePath) : m String := do
  if !(← TerminalEnv.pathExists dir) then return ""
  if !(← TerminalEnv.isDir dir) then return ""
  let entries ← TerminalEnv.readDir dir
  let mut acc := ""
  for entryPath in entries do
    if (← TerminalEnv.isDir entryPath) then
      let res ← nativeGlob pat entryPath
      acc := acc ++ res
    else
      let patClean := pat.replace "*" ""
      let fileName ← TerminalEnv.getFileName entryPath
      if fileName.contains patClean then
        acc := acc ++ s!"{entryPath}
"
  return acc

end Pakila
