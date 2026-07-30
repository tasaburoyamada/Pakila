import Pakila.CLI.Theme

namespace Pakila

def replicate (n : Nat) (c : Char) : String :=
  let rec loop (acc : String) (count : Nat) : String :=
    match count with
    | 0 => acc
    | n + 1 => loop (acc.push c) n
  loop "" n

structure ProgressBar where
  total : Nat
  current : Nat
  label : String
deriving Repr

/-- 決定論的プログレスバーレンダラー (3-A 拡張) -/
def ProgressBar.render (pb : ProgressBar) : String :=
  let percentage := if pb.total == 0 then 0 else (pb.current * 100) / pb.total
  let filled := if pb.total == 0 then 0 else (pb.current * 20) / pb.total
  let bar := applyColor Color.cyan (replicate filled '█') ++ applyColor ProfessionalColors.gray (replicate (20 - filled) '░')
  s!"{pb.label} [{bar}] {percentage}%"

def ProgressBar.update (pb : ProgressBar) (newCurrent : Nat) : ProgressBar :=
  { pb with current := min newCurrent pb.total }

/-- アニメーションスピナーフレーム (3-B) -/
def spinnerFrames : Array String :=
  #["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

def getSpinnerFrame (step : Nat) : String :=
  let idx := step % spinnerFrames.size
  applyColor Color.yellow (spinnerFrames.getD idx "⠋")

/-- リッチステータスバー・オーバーレイレンダラー (3-C) -/
structure StatusOverlay where
  activeTask : String
  memoryUsageMb : Nat := 0
  activeModel : String := "Gemini"
deriving Repr

def StatusOverlay.render (status : StatusOverlay) : String :=
  let content := s!" [ Task: {status.activeTask} | Model: {status.activeModel} | Mem: {status.memoryUsageMb}MB ] "
  let bar := applyColor ProfessionalColors.gray (replicate (max 0 (80 - content.length)) "─")
  applyColor Color.cyan content ++ bar

end Pakila
