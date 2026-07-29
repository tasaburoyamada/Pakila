import Pakila.Core.Interface
import Pakila.Core.Environment
import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila

/-- 
特定のファイルのMessagePartを取得する内部関数
-/
def getFileParts (pathStr : String) : IO (List MessagePart) := do
  let path := System.FilePath.mk pathStr
  if (← path.pathExists) == false then return []
  let ext := path.extension.getD ""
  
  if ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "webp" then do
    let data ← TerminalEnv.readBinFile path
    let mime := if ext == "png" then "image/png" else if ext == "webp" then "image/webp" else "image/jpeg"
    return [.image mime data]
  
  if ext == "mp3" || ext == "wav" then do
    let data ← TerminalEnv.readBinFile path
    let mime := if ext == "mp3" then "audio/mpeg" else "audio/wav"
    return [.audio mime data]
  
  let m ← path.metadata
  if m.byteSize > 5 * 1024 * 1024 then
    return [.text s!"[File {pathStr} is too large to inject (max 5MB)]"]
  
  try
    let content ← TerminalEnv.readFile path
    return [.text s!"\n--- {pathStr} ---\n{content}\n---"]
  catch e =>
    return [.text s!"[Failed to read {pathStr}: {e}]"]

/-- 
プロンプト文字列内の @path を検知し、ファイル内容を注入する。
マルチモーダル対応: 拡張子に応じて MessagePart を生成する。
-/
def injectFileParts (input : String) : IO (List MessagePart) := do
  let words := input.splitOn " "
  let mut parts : List MessagePart := []
  let mut currentText := ""

  let flushText (t : String) (acc : List MessagePart) : List MessagePart :=
    if t.isEmpty then acc else acc ++ [.text t.trimAscii.toString]

  for w in words do
    if w.startsWith "@" then do
      let pathStr := (w.drop 1).toString
      let newParts ← getFileParts pathStr
      if newParts.isEmpty == false then
        currentText := currentText.trimAscii.toString
        parts := flushText currentText parts
        currentText := ""
        parts := parts ++ newParts
      else
        currentText := currentText ++ " " ++ w
    else
      currentText := currentText ++ " " ++ w
  
  return flushText currentText parts

end Pakila
