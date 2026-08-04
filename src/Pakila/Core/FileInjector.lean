import Pakila.Core.Interface
import Pakila.Core.Environment
import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference

open Lyceum
open Pakila

namespace Pakila

/-- 
特定のファイルのMessagePartを取得する内部関数
-/
def getFileParts (pathStr : String) : IO (List MessagePart) := do
  let cleanPathStr := pathStr.trimAscii.toString
  let path := System.FilePath.mk cleanPathStr
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
    return [.text s!"[File {cleanPathStr} is too large to inject (max 5MB)]"]
  
  try
    let content ← TerminalEnv.readFile path
    return [.text s!"\n--- {cleanPathStr} ---\n{content}\n---"]
  catch e =>
    return [.text s!"[Failed to read {cleanPathStr}: {e}]"]

/-- 
プロンプト文字列内の @path を検知し、ファイル内容を注入する。
クォート囲みパス（@"path with space"）および @path の完全解析対応。
-/
def injectFileParts (input : String) : IO (List MessagePart) := do
  let mut parts : Array MessagePart := #[]
  let mut currentText := ""
  let mut pos : Nat := 0
  let endPos : Nat := input.length

  while pos < endPos do
    let c := input.get ⟨pos⟩
    if c == '@' then
      let nextPos := pos + 1
      if nextPos < endPos && input.get ⟨nextPos⟩ == '"' then
        -- クォート囲みパスの解析 @"..."
        let pathStart := nextPos + 1
        let mut pathEnd := pathStart
        let mut foundQuote := false
        while pathEnd < endPos do
          if input.get ⟨pathEnd⟩ == '"' then
            foundQuote := true
            break
          pathEnd := pathEnd + 1
        
        if foundQuote then
          let pathStr := (input.toList.drop pathStart |>.take (pathEnd - pathStart)) |> String.ofList
          let newParts ← getFileParts pathStr
          if !newParts.isEmpty then
            if !currentText.isEmpty then
              parts := parts.push (.text currentText.trimAscii.toString)
              currentText := ""
            parts := parts.append newParts.toArray
            pos := pathEnd + 1
            continue

      -- 通常の空白区切りパス解析 @path
      let pathStart := nextPos
      let mut pathEnd := pathStart
      while pathEnd < endPos do
        let ch := input.get ⟨pathEnd⟩
        if ch == ' ' || ch == '\t' || ch == '\n' then break
        pathEnd := pathEnd + 1

      let pathStr := (input.toList.drop pathStart |>.take (pathEnd - pathStart)) |> String.ofList
      if !pathStr.isEmpty then
        let newParts ← getFileParts pathStr
        if !newParts.isEmpty then
          if !currentText.isEmpty then
            parts := parts.push (.text currentText.trimAscii.toString)
            currentText := ""
          parts := parts.append newParts.toArray
          pos := pathEnd
          continue

      currentText := currentText.push c
      pos := nextPos
    else
      currentText := currentText.push c
      pos := pos + 1

  if !currentText.isEmpty then
    parts := parts.push (.text currentText.trimAscii.toString)

  return parts.toList

end Pakila
