import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State

open Lyceum

--TEMP_MARKER--

namespace Pakila

/-- Pakila の基本実行モナド -/
abbrev PakilaM := StateT InterpreterState IO

/-- PakilaM でエラーを扱うための共用型 -/
abbrev PakilaResult α := ExceptT AppError PakilaM α

/-- PakilaM の実行実行関数 -/
def runPakilaM (action : PakilaResult α) (initialState : InterpreterState) : IO (Except AppError α × InterpreterState) :=
  action.run initialState

end Pakila
