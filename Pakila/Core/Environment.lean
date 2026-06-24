import Lean
import Init.System.IO
import Init.System.FilePath
import Pakila.Plugins.FFI
import Pakila.Core.Interface
import Pakila.CLI.Theme

namespace Pakila

-- /-- 物理ターミナルの状態を保持するグローバルRef -/
-- initialize rawModeRef : IO.Ref Bool ← IO.mkRef false

/-- 物理RAWモード設定のFFI定義 -/
-- @[extern "lean_enable_raw_mode"]
opaque enableRawModeNative (dummy : Unit) : IO Bool

-- @[extern "lean_disable_raw_mode"]
opaque disableRawModeNative (dummy : Unit) : IO Unit

-- @[extern "lean_get_char"]
opaque getCharNative (dummy : Unit) : IO UInt8

-- @[extern "lean_get_terminal_size"]
opaque getTerminalSizeNative (dummy : Unit) : IO (Nat × Nat)

/-- 実機 (IOモナド) 用の物理環境実装 -/
-- TerminalEnv IO インスタンスは Pakila.CLI.TerminalIO に移動したため、
-- このファイルにはインスタンス定義は含みません。

-- loadHistory path := do ... (他のユーティリティ関数も同様に削除またはコメントアウト)

--  Himachal.Core.Interface から TerminalEnv 型クラスをインポートしているため、
-- ここでインスタンスを定義する必要はありません。
-- もし Pakila.CLI.TerminalIO が TerminalEnv IO のインスタンスを定義しているなら、
-- Pakila.Core.Environment ではそれを参照するだけで十分です。
-- 実際には、TerminalEnv IO のインスタンスは 1 つしか存在できないため、
-- Pakila.CLI.TerminalIO で定義されたインスタンスが参照されるはずです。

end Pakila
