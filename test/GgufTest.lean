import Pakila.Gguf.Parser

import Pakila.Core.Environment

open Pakila
open Pakila.Gguf

def main : IO Unit := do
  let homePath ← getHomeDir
  let modelsDir := homePath / "models"
  
  if !(← modelsDir.pathExists) then
    IO.println s!"Models directory not found: {modelsDir}"
    return

  let entries ← modelsDir.readDir
  for entry in entries do
    if entry.fileName.endsWith ".gguf" then
      IO.println s!"Analyzing: {entry.fileName}"
      match (← parseGgufMetadata (modelsDir / entry.fileName |>.toString)) with
      | .ok (header, kvs) =>
          IO.println s!"  Version: {header.version}"
          IO.println s!"  Metadata Count: {header.metadataCount}"
          
          -- 全てのキーを表示（デバッグ用）
          for (k, _) in kvs do
             IO.println s!"  Key: {k}"

          -- トークナイザー関連のキーを抽出
          for (k, v) in kvs do
            if k.contains "tokenizer.ggml" then
              match v with
              | .string s => IO.println s!"  {k}: {s}"
              | .array _ elms => 
                  IO.println s!"  {k}: [Array size={elms.size}]"
                  if elms.size > 0 then
                    let sample := elms.extract 0 (min 3 elms.size) |>.toList
                    IO.println s!"    Sample: {repr sample}"
              | _ => IO.println s!"  {k}: {repr v}"
      | .error e => IO.println s!"  Error: {e}"
