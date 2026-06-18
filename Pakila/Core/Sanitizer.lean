import Lyceum.Types
import Lyceum.Inference

open Lyceum

--TEMP_MARKER--

namespace Pakila.Core.Sanitizer

/-- 
機密情報をサニタイズする。
APIキーや特定の環境変数パターンを [REDACTED] に置換する。
-/
def sanitize (text : String) (patterns : List String) : String :=
  let rec loop (t : String) (ps : List String) :=
    match ps with
    | [] => t
    | p :: rest => 
        if p.isEmpty then loop t rest
        else loop (t.replace p "[REDACTED]") rest
  loop text patterns

/-- 物理的な保護壁: Stdout への出力直前に適用する -/
def sanitizeStdout (text : String) : IO String := do
  -- 実際には config から API キー等を取得
  let apiKey ← IO.getEnv "GEMINI_API_KEY"
  return sanitize text [apiKey.getD ""]

end Pakila.Core.Sanitizer
