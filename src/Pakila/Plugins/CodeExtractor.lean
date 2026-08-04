import Lyceum.Types
import Lyceum.Inference
import Pakila.Util.String

open Lyceum

namespace Pakila

/-- 文字列 s が sub を含んでいるか確認するヘルパー -/
def containsSubstr (s sub : String) : Bool :=
  if sub.isEmpty then true
  else (s.splitOn sub).length > 1

/-- 
Markdown テキストから特定の言語のコードブロックを抽出する (純粋再帰・型保証)。
例: ```bash ... ```
-/
def extractCodeBlocks (text : String) (lang : String) : List String :=
  let lines := text.splitOn "\n"
  let target := s!"```{lang}"
  let rec loop (lines : List String) (inBlock : Bool) (acc : List String) (current : String) : List String :=
    match lines with
    | [] => acc.reverse
    | line :: rest =>
      let trimmed := line.trimAscii.toString
      if inBlock then
        if trimmed.startsWith "```" then
          loop rest false (current.trimAscii.toString :: acc) ""
        else
          loop rest true acc (current ++ line ++ "\n")
      else
        if trimmed.startsWith target then
          loop rest true acc ""
        else
          loop rest false acc ""
  
  loop lines false [] ""

/-- 
update_topic(title="...") 形式からタイトルを抽出する (正規インデックス切り出し)。
-/
def extractTopicUpdate (text : String) : Option String :=
  let target := "title=\""
  let parts := text.splitOn target
  if parts.length > 1 then
    let titlePart := parts[1]!
    let title := titlePart.takeWhile (fun c => c != '"')
    some title.toString
  else none

end Pakila
