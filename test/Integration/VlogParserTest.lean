import Lyceum.Types
import Lyceum.Inference
import Pakila.Governance.Vlog
import Pakila.Governance.VlogParser

open Lyceum

--TEMP_MARKER--

open Pakila

def runTest (name : String) (test : IO (Except String Unit)) : IO Unit := do
  IO.println s!"Running test: {name}..."
  match (← test) with
  | .ok _ => IO.println s!"[PASS] {name}"
  | .error e => IO.println s!"[FAIL] {name}: {e}"

/-- VlogParser: 複雑な入力の検証 -/
def testComplexVlog : IO (Except String Unit) := do
  let vlogs := "
# Comment line
@CTX:[DOM:PROJECT|SUB:TEST|GOAL:ROBUSTNESS]
@BIAS:{P:0.1,M:0.2,S:0.3,D:0.4,C:0.5}
@DELTA(WINNER>LOSER)
+ [ENABLE_FEATURE]
- [DISABLE_FEATURE]
! [MANDATORY]
[[CONCEPT_A]] [[CONCEPT_B]]
"
  match parseVlogString vlogs with
  | .ok nodes =>
      if nodes.length != 7 then return Except.error s!"Expected 7 nodes, got {nodes.length}"
      
      -- 個別ノードの検証
      let hasCtx := nodes.any (fun n => match n with | .Ctx "PROJECT" "TEST" "ROBUSTNESS" => true | _ => false)
      if !hasCtx then return Except.error "Ctx node mismatch"
      
      let hasBias := nodes.any (fun n => match n with 
        | .Bias p m s d c => p == 0.1 && m == 0.2 && s == 0.3 && d == 0.4 && c == 0.5
        | _ => false)
      -- Float の比較は BEq で行われるが、リテラルとの完全一致を期待
      if !hasBias then return Except.error "Bias node mismatch"

      let hasConcept := nodes.any (fun n => match n with | .Concept ["CONCEPT_A", "CONCEPT_B"] => true | _ => false)
      if !hasConcept then return Except.error "Concept node mismatch"

      return Except.ok ()
  | .error e => return Except.error s!"Parse failed: {e}"

def main : IO Unit := do
  IO.println "=== Pakila Vlog Parser Edge Case Test Suite ==="
  runTest "ComplexVlog" testComplexVlog
