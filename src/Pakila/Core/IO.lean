import Lean

namespace Pakila.Core.IO

/-- 標準入力からの行読み込み -/
def readLine : IO String := _root_.IO.getLine

/-- 標準出力への書き込み -/
def print (s : String) : IO Unit := _root_.IO.print s

/-- 標準出力への書き込み（改行あり） -/
def println (s : String) : IO Unit := _root_.IO.println s

/-- ファイル書き込み -/
def writeFile (path : System.FilePath) (content : String) : IO Unit := _root_.IO.FS.writeFile path content

/-- ファイル読み込み -/
def readFile (path : System.FilePath) : IO String := _root_.IO.FS.readFile path

end Pakila.Core.IO
