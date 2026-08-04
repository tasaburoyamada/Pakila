import Lyceum.Types
import Lyceum.Inference

open Lyceum

namespace Pakila

/-- 認知負荷に基づいたUI適応パラメータ -/
structure CognitiveConfig where
  maxUpdateFreqMs : Nat := 100 -- 人間の知覚限界に合わせた更新頻度
  informationDensity : Float := 0.5 -- 0.0 to 1.0 (1.0: 全文表示, 0.0: 最小要約)
deriving Repr, BEq, Inhabited

/--
情報密度 (density 0.0 ~ 1.0) に応じた文字数サンプリングとトランケーション。
ダミースタブを排除し、文字境界を保った型安全な視覚適応を提供する。
-/
def filterLowPriorityInfo (text : String) (density : Float) : String :=
  let clampedDensity := max 0.0 (min 1.0 density)
  if clampedDensity >= 0.99 then text
  else if clampedDensity <= 0.05 then
    if text.isEmpty then "" else (text.take 30).toString ++ "..."
  else
    let targetLength := (text.length.toFloat * clampedDensity).toUInt64.toNat
    if targetLength >= text.length then text
    else (text.take (max 10 targetLength)).toString ++ "..."

end Pakila
