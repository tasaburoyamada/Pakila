import Lean
import Lyceum.Types
import Lyceum.Inference
import Pakila.Memory.Embedding
import Pakila.Memory.Native
import Pakila.Core.Environment

open Lyceum
open Pakila

--TEMP_MARKER--

namespace Pakila.Memory

open Lean hiding Message

deriving instance Repr for Json

/-- 
ベクトルデータベースのエントリー。
ベクトルデータに加えて、元のテキストやメタデータを保持する。
-/
structure VectorEntry where
  id : String
  text : String
  vector : Vector
  metadata : Json := Json.null
deriving Repr, Inhabited, ToJson, FromJson

/--
インメモリーのベクトルデータベース。
-/
structure VectorDB where
  entries : Array VectorEntry := #[]
deriving Repr, Inhabited, ToJson, FromJson

instance : EmptyCollection VectorDB where
  emptyCollection := { entries := #[] }

/-- 
コサイン類似度の計算。
内積 / (ノルム * ノルム)
-/
def cosineSimilarity (v1 v2 : Vector) : Float := Id.run do
  let d1 := v1.data
  let d2 := v2.data
  if d1.size != d2.size || d1.size == 0 then return 0.0
  else
    let fa1 := FloatArray.mk d1
    let fa2 := FloatArray.mk d2
    let dot := Native.dotProductNative fa1 fa2
    let n1 := Native.normNative fa1
    let n2 := Native.normNative fa2
    if n1 == 0.0 || n2 == 0.0 then return 0.0
    else return dot / (n1 * n2)

/--
ベクトル検索。
クエリベクトルに対して、類似度スコアが閾値以上のものを抽出し、
スコアの降順で上位K件を返す。
-/
def VectorDB.search (self : VectorDB) (query : Vector) (topK : Nat) (threshold : Float := 0.5) : Array (VectorEntry × Float) :=
  let scored := self.entries.filterMap (fun entry =>
    let score := cosineSimilarity query entry.vector
    if score >= threshold then some (entry, score) else none
  )
  -- Floatの比較用にソート
  let sorted := scored.qsort (fun a b => a.2 > b.2)
  sorted.extract 0 topK

/--
データベースへのエントリー追加。
-/
def VectorDB.insert (self : VectorDB) (entry : VectorEntry) : VectorDB :=
  { self with entries := self.entries.push entry }

/-- 永続化: ファイルへ保存 -/
def VectorDB.save (self : VectorDB) (path : String) : IO Unit := do
  let json := Lean.toJson self
  TerminalEnv.writeFile (System.FilePath.mk path) json.pretty

/-- 永続化: ファイルから読込 -/
def VectorDB.load (path : String) : IO (Except String VectorDB) := do
  if !(← System.FilePath.pathExists path) then
    return .ok ∅
  let content ← TerminalEnv.readFile (System.FilePath.mk path)
  match Lean.Json.parse content with
  | .ok json => 
      match Lean.fromJson? json with
      | .ok db => return .ok db
      | .error e => return .error s!"JSON Decode error: {e}"
  | .error e => return .error s!"JSON Parse error: {e}"

end Pakila.Memory
