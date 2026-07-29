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

/-- @DENSITY_FOCUS[target] のパース -/
def parseDensityFocus : Parser VlogNode := do
  let _ ← pstring "@DENSITY_FOCUS["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .DensityFocus content.trimAscii.toString

/-- @DENSITY_SLACK[target] のパース -/
def parseDensitySlack : Parser VlogNode := do
  let _ ← pstring "@DENSITY_SLACK["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .DensitySlack content.trimAscii.toString

/-- @CADENCE_DYNA[10,120,8] のパース -/
def parseCadenceDyna : Parser VlogNode := do
  let _ ← pstring "@CADENCE_DYNA["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let nums := content.splitOn "," |>.filterMap (fun s => s.trimAscii.toString.toNat?)
  return .CadenceDyna nums

/-- @IRREVERSIBLE:[BEFORE:b|AFTER:a] のパース -/
def parseIrreversible : Parser VlogNode := do
  let _ ← pstring "@IRREVERSIBLE:["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  let mut b := ""; let mut a := ""
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "BEFORE" then b := v
      else if k == "AFTER" then a := v
  return .IrreversibleShift b a

/-- @GAP:[PRED:p|REALITY:r] のパース -/
def parseExpectationGap : Parser VlogNode := do
  let _ ← pstring "@GAP:["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  let mut p := ""; let mut r := ""
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "PRED" then p := v
      else if k == "REALITY" then r := v
  return .ExpectationGap p r

/-- @TRADEOFF:[OPTION_A:a|OPTION_B:b] のパース -/
def parseConflictTradeoff : Parser VlogNode := do
  let _ ← pstring "@TRADEOFF:["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  let mut a := ""; let mut b := ""
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "OPTION_A" then a := v
      else if k == "OPTION_B" then b := v
  return .ConflictTradeoff a b

/-- @NARRATIVE:[ROLE:r|TONE:t] のパース -/
def parseNarrativePerspective : Parser VlogNode := do
  let _ ← pstring "@NARRATIVE:["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  let mut r := ""; let mut t := ""
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "ROLE" then r := v
      else if k == "TONE" then t := v
  return .NarrativePerspective r t

/-- @SANCTUARY[target] のパース -/
def parseSanctuary : Parser VlogNode := do
  let _ ← pstring "@SANCTUARY["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .Sanctuary content.trimAscii.toString

/-- @FRICTION[conflict] のパース -/
def parseFriction : Parser VlogNode := do
  let _ ← pstring "@FRICTION["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .Friction content.trimAscii.toString

/-- @LOGICAL_CRUSH[logic] のパース -/
def parseLogicalCrush : Parser VlogNode := do
  let _ ← pstring "@LOGICAL_CRUSH["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .LogicalCrush content.trimAscii.toString

/-- @STAIN[stain] のパース -/
def parseIrreversibleStain : Parser VlogNode := do
  let _ ← pstring "@STAIN["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .IrreversibleStain content.trimAscii.toString

/-- @CORE_VALUE[target] のパース -/
def parseCoreValue : Parser VlogNode := do
  let _ ← pstring "@CORE_VALUE["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .CoreValue content.trimAscii.toString

/-- @IDIOLECT:[TONE:t|HABIT:h] のパース -/
def parseIdiolect : Parser VlogNode := do
  let _ ← pstring "@IDIOLECT:["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  let mut t := ""; let mut h := ""
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "TONE" then t := v
      else if k == "HABIT" then h := v
  return .Idiolect t h

/-- @INFO_BOUND:[KNOWN:k|UNKNOWN:u] のパース -/
def parseInformationBoundary : Parser VlogNode := do
  let _ ← pstring "@INFO_BOUND:["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  let mut kStr := ""; let mut uStr := ""
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "KNOWN" then kStr := v
      else if k == "UNKNOWN" then uStr := v
  return .InformationBoundary kStr uStr

/-- @TIMELINE:[STAGE:s|ACCUM:e] のパース -/
def parseTimelinePhase : Parser VlogNode := do
  let _ ← pstring "@TIMELINE:["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  let parts := content.splitOn "|"
  let mut s := ""; let mut e := ""
  for part in parts do
    let kv := part.splitOn ":"
    if kv.length == 2 then
      let k := kv[0]!.trimAscii.toString
      let v := kv[1]!.trimAscii.toString
      if k == "STAGE" then s := v
      else if k == "ACCUM" then e := v
  return .TimelinePhase s e

/-- @LIFELINE[target] のパース -/
def parseDataLifeline : Parser VlogNode := do
  let _ ← pstring "@LIFELINE["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .DataLifeline content.trimAscii.toString

/-- @CONTRACT[semantics] のパース -/
def parseContractIntegrity : Parser VlogNode := do
  let _ ← pstring "@CONTRACT["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .ContractIntegrity content.trimAscii.toString

/-- @BOUNDS[limits] のパース -/
def parsePhysicalBoundary : Parser VlogNode := do
  let _ ← pstring "@BOUNDS["
  let content ← manyChars (satisfy (· ≠ ']'))
  let _ ← pchar ']'
  return .PhysicalBoundary content.trimAscii.toString

def vlogNodeParser : Parser VlogNode :=
  parseCtx <|> parseBias <|> parseDelta <|> parseShift <|> parseConcept <|> parseDensityFocus <|> parseDensitySlack <|> parseCadenceDyna <|> parseIrreversible <|> parseExpectationGap <|> parseConflictTradeoff <|> parseNarrativePerspective <|> parseSanctuary <|> parseFriction <|> parseLogicalCrush <|> parseIrreversibleStain <|> parseCoreValue <|> parseIdiolect <|> parseInformationBoundary <|> parseTimelinePhase <|> parseDataLifeline <|> parseContractIntegrity <|> parsePhysicalBoundary

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

/-- VlogNodeのリストからプロンプト注入用の文字列を生成する -/
def formatVlogState (nodes : List VlogNode) : String :=
  if nodes.isEmpty then ""
  else
    let header := "## [HV-CAD Vector-State Injection & Architectural Auditor Mandate]\n"
    nodes.foldl (fun acc node =>
      match node with
      | .Ctx d s g => acc ++ s!"- Context: Domain={d}, Sub={s}, Goal={g}\n"
      | .Bias p m s d c => acc ++ s!"- Bias Weights: P={p}, M={m}, S={s}, D={d}, C={c}\n"
      | .Delta w l => acc ++ s!"- Decision Delta: {w} > {l}\n"
      | .ShiftPlus t => acc ++ s!"- Enabled Constraint: {t}\n"
      | .ShiftMinus t => acc ++ s!"- Suppressed Constraint: {t}\n"
      | .ShiftMandatory t => acc ++ s!"- Mandatory Constraint: {t}\n"
      | .Concept ts => acc ++ s!"- Active Concepts: {ts}\n"
      | .DensityFocus t => acc ++ s!"- [HIGH-DENSITY FOCUS]: Eliminate generalities/filler. Concentrate exact facts & structure on: {t}\n"
      | .DensitySlack t => acc ++ s!"- [LOW-DENSITY SLACK]: State concisely in 1-2 sentences. Retain spatial/cultural silence on: {t}\n"
      | .CadenceDyna pat => acc ++ s!"- [CADENCE RHYTHM DYNAMICS]: Vary sentence lengths sharply according to sequence [{String.intercalate ", " (pat.map toString)}]\n"
      | .IrreversibleShift b a => acc ++ s!"- [IRREVERSIBLE STATE TRANSITION]: Permanently transform state from '{b}' -> '{a}'. DO NOT reset to initial state.\n"
      | .ExpectationGap p r => acc ++ s!"- [EXPECTATION GAP / SUBVERSION]: Undermine user's implicit prediction '{p}' with logical reality '{r}'.\n"
      | .ConflictTradeoff a b => acc ++ s!"- [GENUINE CONFLICT TRADEOFF]: Enforce unavoidable choice between '{a}' vs '{b}'. Both must entail severe cost.\n"
      | .NarrativePerspective r t => acc ++ s!"- [NARRATIVE PERSPECTIVE & TONE]: Adopt narrator role '{r}' with tone '{t}'.\n"
      | .Sanctuary v => acc ++ s!"- [STEP 1 SANCTUARY]: Build highly sophisticated, unyielding moral/idealistic sanctuary around: {v}\n"
      | .Friction c => acc ++ s!"- [STEP 2 FRICTION]: Depict fierce internal conflict between the unyielding principle and: {c}\n"
      | .LogicalCrush l => acc ++ s!"- [STEP 3 LOGICAL CRUSH]: Deconstruct the virtue through rigorous, inescapable logic of: {l}\n"
      | .IrreversibleStain s => acc ++ s!"- [STEP 4 IRREVERSIBLE STAIN]: Depict the enduring spiritual stain and dark aesthetic where the entity observes its own ruined virtue: {s}\n"
      | .CoreValue p => acc ++ s!"- [CHARACTER CORE VALUE]: Unyielding core identity & choice principle: {p}. DO NOT drift or alter without explicit narrative cause.\n"
      | .Idiolect t h => acc ++ s!"- [CHARACTER IDIOLECT & PERSONA]: Persona tone '{t}', speech habit '{h}'. Maintain inviolable voice identity.\n"
      | .InformationBoundary k u => acc ++ s!"- [INFORMATION BOUNDARY / ASYMMETRY]: Known facts '{k}', Blindspots/Unknowns '{u}'. Strictly prohibit meta-knowledge leakage.\n"
      | .TimelinePhase s e => acc ++ s!"- [TIMELINE & EXPERIENCE STAGE]: Growth stage '{s}', Accumulated experience '{e}'. Reflect depth of losses & gains.\n"
      | .DataLifeline d => acc ++ s!"- [DATA LIFELINE INTEGRITY]: Ensure unbroken physical context & linguistic consistency across: {d}\n"
      | .ContractIntegrity c => acc ++ s!"- [CONTRACT INTEGRITY AUDIT]: Fulfill exact semantic promise without empty fallbacks or silent swallows for: {c}\n"
      | .PhysicalBoundary p => acc ++ s!"- [PHYSICAL BOUNDARY CONTROL]: Enforce non-averaging entropy, rate limits, and fallback bounds for: {p}\n"
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

-- ===========================================================================
-- 試案㋢： @BIAS → LlmRequestOptions 物理マッピング
-- ===========================================================================

/--
@BIASノードの各パラメータを LlmRequestOptions に変換する。

パラメータ定義：
  - D (Determinism, 0.0–1.0): 高いほど決定論的。temperature = 1.0 - D
  - P (Precision,    0.0–1.0): 语彙分布の集中度。topP としてそのまま使用。
  - M (MaxContext,   0.0–1.0): 将来の maxTokens 制御用に保留（現時点未接続）。
  - S, C: テキスト注入側の強調度制御用に保留。
-/
def biasToRequestOptions (nodes : List VlogNode) : Option Lyceum.LlmRequestOptions :=
  let biasOpt := nodes.findSome? (fun n => match n with | .Bias p m s d c => some (p, m, s, d, c) | _ => none)
  match biasOpt with
  | none => none
  | some (p, _m, _s, d, _c) =>
    let temperature := some (max 0.0 (min 2.0 (1.0 - d)))
    let topP        := if p > 0.0 && p <= 1.0 then some p else none
    some { temperature := temperature, topP := topP, maxTokens := none }

-- ===========================================================================
-- 試案㋣： ! (Mandatory) 制約のプリフライトチェック
-- ===========================================================================

/--
@ShiftMandatory ノードの制約名リストを抽出する。
-/
def extractMandatoryConstraints (nodes : List VlogNode) : List String :=
  nodes.filterMap (fun n => match n with | .ShiftMandatory t => some t | _ => none)

/--
制約名と入力テキストによるキーワード照合による充足判定。
制約名の各トークン（アンダースコア分割）が入力に存在すれば充足とみなす。
不充足の場合は PolicyViolation エラーを返す。
-/
def checkMandatoryConstraints
    (nodes : List VlogNode) (input : String) : Except Lyceum.AppError Unit :=
  let constraints := extractMandatoryConstraints nodes
  let inputLower := input.toLower
  -- 制約名を "_" で分割し、どのトークンも入力に含まれない制約を未充足とみなす
  let unmet := constraints.filter (fun constraint =>
    let tokens := (constraint.toLower).splitOn "_"
    !tokens.any (fun token => !token.isEmpty && inputLower.contains token))
  match unmet with
  | [] => .ok ()
  | vs => .error (.PolicyViolation s!"Mandatory constraints not satisfied: {vs}")

end Pakila
