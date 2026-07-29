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

def ProgressBar.render (pb : ProgressBar) : String :=
  let percentage := if pb.total == 0 then 0 else (pb.current * 100) / pb.total
  let filled := if pb.total == 0 then 0 else (pb.current * 20) / pb.total
  let bar := replicate filled '█' ++ replicate (20 - filled) '░'
  s!"{pb.label} [{bar}] {percentage}%"

def ProgressBar.update (pb : ProgressBar) (newCurrent : Nat) : ProgressBar :=
  { pb with current := min newCurrent pb.total }

end Pakila
