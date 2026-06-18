import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference

open Lyceum

--TEMP_MARKER--

namespace Pakila.CLI.Protocol

open Lean hiding Message

/-- Strategic Response Protocol (SRP) の5セクション構成 -/
structure SrpResponse where
  topic : String := "General"
  intent : String := "Processing request"
  body : String := ""
  summary : String := ""
  status : String := "Success"
deriving ToJson, FromJson, Repr, Inhabited

/-- 
LLM の平文出力から SRP セクションを抽出する。
タグ [Topic Model], [Strategic Intent], [Summary], [Status] を利用する。
-/
def parseSrp (text : String) : SrpResponse := Id.run do
  let lines := text.splitOn "\n"
  let mut res : SrpResponse := {}
  let mut currentBody := ""
  
  for line in lines do
    if line.startsWith "[Topic Model]:" then
      res := { res with topic := line.drop 14 |>.trimAscii.toString }
    else if line.startsWith "[Strategic Intent]:" then
      res := { res with intent := line.drop 18 |>.trimAscii.toString }
    else if line.startsWith "[Summary]:" then
      res := { res with summary := line.drop 10 |>.trimAscii.toString }
    else if line.startsWith "[Status]:" then
      res := { res with status := line.drop 8 |>.trimAscii.toString }
    else if line.startsWith "Body:" then
      pure ()
    else
      currentBody := currentBody ++ line ++ "\n"
  
  return { res with body := currentBody.trimAscii.toString }

/-- SRP 形式で整形する -/
def formatSrp (srp : SrpResponse) : String :=
  s!"[Topic Model]: {srp.topic}\n" ++
  s!"[Strategic Intent]: {srp.intent}\n\n" ++
  s!"{srp.body}\n\n" ++
  s!"[Summary]: {srp.summary}\n" ++
  s!"[Status]: {srp.status}"

end Pakila.CLI.Protocol
