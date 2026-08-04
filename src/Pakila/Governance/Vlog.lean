import Lean.Data.Json
import Lyceum.Types

namespace Pakila

open Lean

/-- 
1. 物理レイヤー: LLM推論エンジン（API / FFI）へ直接渡す物理パラメータ & トークン制御
-/
structure PhysicalVlogConfig where
  temperature     : Option Float := none
  topP            : Option Float := none
  maxTokens       : Option Nat := none
  logitBias       : List (String × Float) := []
  stopSequences   : List String := []
deriving Repr, BEq, Inhabited, ToJson, FromJson

/-- 
2. 意味レイヤー: プロンプトコンテクストへ注入する概念・制約
-/
structure SemanticVlogConfig where
  domain          : String := ""
  subDomain       : String := ""
  goal            : String := ""
  mandatory       : List String := []
  concepts        : List String := []
deriving Repr, BEq, Inhabited, ToJson, FromJson

/-- 
統合 Vlog コンテナ (二層分離 + トークン制御物理マッピング)
-/
structure VlogSpec where
  physical : PhysicalVlogConfig := {}
  semantic : SemanticVlogConfig := {}
deriving Repr, BEq, Inhabited, ToJson, FromJson

/-- 過去の互換性のための VlogNode 定義 -/
inductive VlogNode where
  | Ctx (domain sub goal : String)
  | Bias (p m s d c : Float)
  | Delta (winner loser : String)
  | ShiftPlus (token : String)
  | ShiftMinus (token : String)
  | ShiftMandatory (token : String)
  | Concept (tokens : List String)
  | DensityFocus (target : String)
  | DensitySlack (target : String)
  | CadenceDyna (pattern : List Nat)
  | IrreversibleShift (beforeState afterState : String)
  | ExpectationGap (pred reality : String)
  | ConflictTradeoff (optionA optionB : String)
  | NarrativePerspective (role tone : String)
  | Sanctuary (value : String)
  | Friction (conflict : String)
  | LogicalCrush (logic : String)
  | IrreversibleStain (stain : String)
  | CoreValue (principle : String)
  | Idiolect (tone habit : String)
  | InformationBoundary (known unknown : String)
  | TimelinePhase (stage accum : String)
  | DataLifeline (target : String)
  | ContractIntegrity (semantics : String)
  | PhysicalBoundary (limits : String)
  | Spec (spec : VlogSpec)
deriving Repr, BEq, Inhabited, ToJson, FromJson

/-- VlogNode リストから VlogSpec への統合変換 -/
def nodesToSpec (nodes : List VlogNode) : VlogSpec :=
  nodes.foldl (fun spec node =>
    match node with
    | .Ctx d s g => { spec with semantic := { spec.semantic with domain := d, subDomain := s, goal := g } }
    | .Bias p _m _s d _c =>
        let temp := max 0.0 (min 2.0 (1.0 - d))
        let topPVal := if p > 0.0 && p <= 1.0 then some p else none
        { spec with physical := { spec.physical with temperature := some temp, topP := topPVal } }
    | .ShiftMandatory t => { spec with semantic := { spec.semantic with mandatory := spec.semantic.mandatory ++ [t] } }
    | .Concept ts => { spec with semantic := { spec.semantic with concepts := spec.semantic.concepts ++ ts } }
    | .Spec s => s
    | _ => spec
  ) {}

/-- VLOG ノードをシンボリックな文字列へ変換する -/
def vlogNodeToTokens (node : VlogNode) : String :=
  match node with
  | .Ctx dom sub goal => s!"@CTX:[DOM:{dom}|SUB:{sub}|GOAL:{goal}]\n"
  | .Bias p m s d c => s!"@BIAS:{"{"}P:{p}, M:{m}, S:{s}, D:{d}, C:{c}{"}"}\n"
  | .Delta w l => s!"@DELTA({w} > {l})\n"
  | .ShiftPlus t => s!"+ [{t}]\n"
  | .ShiftMinus t => s!"- [{t}]\n"
  | .ShiftMandatory t => s!"! [{t}]\n"
  | .Concept ts => s!"@CONCEPT\n{String.intercalate " " (ts.map (fun t => s!"[[{t}]]"))}\n"
  | .DensityFocus t => s!"@DENSITY_FOCUS[{t}]\n"
  | .DensitySlack t => s!"@DENSITY_SLACK[{t}]\n"
  | .CadenceDyna pat => s!"@CADENCE_DYNA[{String.intercalate "," (pat.map toString)}]\n"
  | .IrreversibleShift b a => s!"@IRREVERSIBLE:[BEFORE:{b}|AFTER:{a}]\n"
  | .ExpectationGap p r => s!"@GAP:[PRED:{p}|REALITY:{r}]\n"
  | .ConflictTradeoff a b => s!"@TRADEOFF:[OPTION_A:{a}|OPTION_B:{b}]\n"
  | .NarrativePerspective r t => s!"@NARRATIVE:[ROLE:{r}|TONE:{t}]\n"
  | .Sanctuary v => s!"@SANCTUARY[{v}]\n"
  | .Friction c => s!"@FRICTION[{c}]\n"
  | .LogicalCrush l => s!"@LOGICAL_CRUSH[{l}]\n"
  | .IrreversibleStain s => s!"@STAIN[{s}]\n"
  | .CoreValue p => s!"@CORE_VALUE[{p}]\n"
  | .Idiolect t h => s!"@IDIOLECT:[TONE:{t}|HABIT:{h}]\n"
  | .InformationBoundary k u => s!"@INFO_BOUND:[KNOWN:{k}|UNKNOWN:{u}]\n"
  | .TimelinePhase s e => s!"@TIMELINE:[STAGE:{s}|ACCUM:{e}]\n"
  | .DataLifeline d => s!"@LIFELINE[{d}]\n"
  | .ContractIntegrity c => s!"@CONTRACT[{c}]\n"
  | .PhysicalBoundary p => s!"@BOUNDS[{p}]\n"
  | .Spec s => s!"@PHYSICAL_TEMP:{s.physical.temperature.getD 1.0}\n"

/-- VLOG 全体をファイルへ書き込む -/
def writeVlog (path : System.FilePath) (nodes : List VlogNode) : IO Unit := do
  let content := (nodes.map vlogNodeToTokens) |> String.join
  IO.FS.writeFile path (content ++ "@EOF\n")

end Pakila
