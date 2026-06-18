import Lean
import Lyceum.Types
import Lyceum.Inference

open Lyceum

--TEMP_MARKER--

namespace Pakila.Test

open Lean hiding Message

/-- 
外部プロセスからの読み込みを、タイムアウト付きで非ブロック的に行うためのヘルパー。
Lean の IO.FS.Handle は getLine がブロッキングのため、
Python スクリプトを介して select で監視する手法に切り替える。
-/
def expectLine (target : String) (timeoutMs : Nat := 2000) : IO Bool := do
  -- Python の select を用いて、パイプを監視する小さなラッパーを呼ぶ
  let child ← IO.Process.spawn {
    cmd := "python3",
    args := #["-c", "import sys, select; ready = select.select([sys.stdin], [], [], " ++ toString (timeoutMs / 1000.0) ++ "); print(sys.stdin.readline() if ready[0] else 'TIMEOUT')"],
    stdin := .piped,
    stdout := .piped
  }
  -- ... (この設計は複雑すぎるため、もっと単純なものにする)
  return false
  
-- 現実的な修正案：IO.FS.Handle を直接使うのをやめ、process の read タイムアウトが効く API を探すか、
-- 子プロセス側で明示的に flush させ、Lean 側は getLine ではなく read 1 でバイト単位で監視し、
-- その都度 monoMsNow をチェックする方針に戻すのが正攻法。
-- 今回の deadlock は、stdout.read 1 がバイト単位でブロックしてしまうため。
-- 実は IO.FS.Handle には waitReadable があるはず。

end Pakila.Test
