import Lyceum.Types
import Lyceum.Inference
import Pakila.Governance.Vlog
import Std.Internal.Parsec
import Pakila.Util.String

open Lyceum
open Std.Internal.Parsec
open Std.Internal.Parsec.String

namespace Pakila

open Lean hiding Message

/-- 文字列パースのユーティリティ -/
def pFloat : Parser Float := do
  let s ← manyChars (digit <|> pchar '.' <|> pchar '-')
  return stringToFloat s

def ws : Parser Unit := do
  let _ ← manyChars (pchar ' ' <|> pchar '\t')
  return ()

/-- @CTX:[DOM:x|SUB:y|GOAL:z] のパース -/
def parseCtx : Parser VlogNode := do
  let _ ← pstring "@CTX:["
  let mut dom := ""; let mut sub := ""; let mut goal := ""
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "DOM" then dom := v
      else if k == "SUB" then sub := v
      else if k == "GOAL" then goal := v
  return .Ctx dom sub goal

/-- @BIAS:{P:0.1,M:0.2,...} のパース -/
def parseBias : Parser VlogNode := do
  let _ ← pstring "@BIAS:{"
  let content ← manyChars (satisfy (· ≠ '}'))
  let _ ← pchar '}'
  let parts := content.splitOn ","
  let mut p := 0.0; let mut m := 0.0; let mut s := 0.0; let mut d := 0.0; let mut c := 0.0
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := stringToFloat (kv[1]!.trimAscii.toString)
      if k == "P" then p := v
      else if k == "M" then m := v
      else if k == "S" then s := v
      else if k == "D" then d := v
      else if k == "C" then c := v
  return .Bias p m s d c

/-- @DELTA(A>B) のパース -/
def parseDelta : Parser VlogNode := do
  let _ ← pstring "@DELTA("
  let content ← manyChars (satisfy (· ≠ ')'))
  let _ ← pchar ')'
  let parts := content.splitOn ">"
  if parts.length == 2 then
    return .Delta parts[0]!.trimAscii.toString parts[1]!.trimAscii.toString
  else
    fail "Invalid Delta format"

/-- Plus/Minus/Exclamation [Constraint] のパース -/
def parseShift : Parser VlogNode := do
  let sign ← pchar '+' <|> pchar '-' <|> pchar '!'
  ws
  let _ ← pchar '['
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  match sign with
  | '+' => return .ShiftPlus content.trimAscii.toString
  | '-' => return .ShiftMinus content.trimAscii.toString
  | '!' => return .ShiftMandatory content.trimAscii.toString
  | _ => fail "Unknown shift"

/-- [[Concept1]] [[Concept2]] のパース -/
def parseConcept : Parser VlogNode := do
  let content ← manyChars (satisfy (fun _ => true))
  let tokens := content.splitOn "]]" 
    |>.map (fun s => s.trimAscii.toString)
    |>.filter (fun s => s.startsWith "[[")
    |>.map (fun s => (s.drop 2).toString)
  if tokens.isEmpty then fail "No concepts found"
  return .Concept tokens

def vlogNodeParser : Parser VlogNode :=
  parseCtx <|> parseBias <|> parseDelta <|> parseShift <|> parseConcept

/-- 個別の行をパースして VlogNode を生成する。 -/
def parseVlogLine (line : String) : Option VlogNode :=
  let line := line.trimAscii.toString
  if line.isEmpty || line.startsWith "#" then none
  else match vlogNodeParser.run line with
    | .ok node => some node
    | .error _ => none

/-- .vlog ファイル全体をパースする -/
def parseVlogString (input : String) : Except String (List VlogNode) :=
  let lines := input.splitOn "\n"
  let nodes := lines.filterMap parseVlogLine
  Except.ok nodes

/-- VlogNode のリストからプロンプト注入用の文字列を生成する -/
def formatVlogState (nodes : List VlogNode) : String :=
  if nodes.isEmpty then ""
  else
    let header := "## [HV-CAD Vector-State Injection]\n"
    nodes.foldl (fun acc node =>
      match node with
      | .Ctx d s g => acc ++ s!"- Context: Domain={d}, Sub={s}, Goal={g}\n"
      | .Bias p m s d c => acc ++ s!"- Bias Weights: P={p}, M={m}, S={s}, D={d}, C={c}\n"
      | .Delta w l => acc ++ s!"- Decision Delta: {w} > {l}\n"
      | .ShiftPlus t => acc ++ s!"- Enabled Constraint: {t}\n"
      | .ShiftMinus t => acc ++ s!"- Suppressed Constraint: {t}\n"
      | .ShiftMandatory t => acc ++ s!"- Mandatory Constraint: {t}\n"
      | .Concept ts => acc ++ s!"- Active Concepts: {ts}\n"
    ) header

/-- メッセージの先頭に .vlog ステートを注入する -/
def injectVlogState (nodes : List VlogNode) (msg : Message) : Message := Id.run do
  if nodes.isEmpty then return msg
  let vlogStr := formatVlogState nodes
  let mut updatedParts := []
  let mut injected := false
  for part in msg.parts do
    match part with
    | .text t => 
        if !injected then
          updatedParts := (.text (vlogStr ++ "\n" ++ t)) :: updatedParts
          injected := true
        else
          updatedParts := part :: updatedParts
    | _ => updatedParts := part :: updatedParts
  
  if !injected then
    updatedParts := (.text vlogStr) :: updatedParts
  
  return { msg with parts := updatedParts.reverse }

end Pakila
