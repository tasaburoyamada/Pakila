import Lean

namespace Pakila

inductive Color where
  | default
  | black
  | red
  | green
  | yellow
  | blue
  | magenta
  | cyan
  | white
  | xterm (n : Nat)
deriving Repr, BEq, Lean.ToJson, Lean.FromJson, Inhabited

def Color.toAnsi : Color -> String
  | .default => "\u001b[39m"
  | .black   => "\u001b[30m"
  | .red     => "\u001b[31m"
  | .green   => "\u001b[32m"
  | .yellow  => "\u001b[33m"
  | .blue    => "\u001b[34m"
  | .magenta => "\u001b[35m"
  | .cyan    => "\u001b[36m"
  | .white   => "\u001b[37m"
  | .xterm n => s!"\u001b[38;5;{n}m"

namespace ProfessionalColors
  def gray : Color := .xterm 242
  def lightYellow : Color := .xterm 229
  def brightWhite : Color := .xterm 231
  def darkGray : Color := .xterm 236
end ProfessionalColors

structure Theme where
  user : Color
  ai : Color
  error : Color
  system : Color
deriving Repr, Lean.ToJson, Lean.FromJson, Inhabited

def applyColor (c : Color) (text : String) : String :=
  c.toAnsi ++ text ++ "\u001b[0m"

def applyBold (text : String) : String :=
  "\u001b[1m" ++ text ++ "\u001b[22m"

end Pakila
