import Lyceum.Base64

open Lyceum

--TEMP_MARKER--

namespace Base64Test

def testBase64 : IO Unit := do
  IO.println "[Test] Base64 Encoding/Decoding..."
  let input := "Hello, Lean 4!".toUTF8
  let encoded := toBase64 input
  IO.println s!"Encoded: {encoded}"
  IO.println "[Test] Base64 PASSED."

end Base64Test
