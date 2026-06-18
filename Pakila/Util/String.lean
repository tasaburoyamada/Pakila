namespace Pakila

def stringToFloat (s : String) : Float :=
  match s.toNat? with
  | some n => n.toFloat
  | none => 0.0

instance : Repr IO.Error where
  reprPrec e _ := s!"IO.Error: {e}"

end Pakila
