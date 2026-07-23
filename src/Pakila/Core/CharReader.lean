import Lean
import Init.System.IO
import Init.Data.Char

namespace Pakila.Core.CharReader

/--
Reads a single UTF-8 character from standard input.
Returns the Unicode codepoint as an Int, or 0 if EOF/error.
This is a simplified implementation and may need further robustness.
-/
def readUtf8CharIO : IO Int :=
do
  let stdin ← IO.getStdin
  let mut buffer : ByteArray := ByteArray.empty
  let mut byteCount := 0

  -- Read the first byte
  let firstByte ← stdin.readByte
  buffer := buffer.push firstByte
  byteCount := 1

  -- Determine the number of bytes expected for a UTF-8 character
  let charByteLength : Nat :=
    if (firstByte &&& 0x80) == 0 then 1 -- ASCII (0xxxxxxx)
    else if (firstByte &&& 0xE0) == 0xC0 then 2 -- 2-byte sequence (110xxxxx)
    else if (firstByte &&& 0xF0) == 0xE0 then 3 -- 3-byte sequence (1110xxxx)
    else if (firstByte &&& 0xF8) == 0xF0 then 4 -- 4-byte sequence (11110xxx)
    else 0 -- Invalid start byte

  if charByteLength == 0 then
    -- Invalid start byte, return replacement char (U+FFFD) or handle error
    return 0xFFFD -- Unicode replacement character
  else if charByteLength > 1 then
    -- Read continuation bytes
    for i in [1 : charByteLength - 1] do
      let nextByte ← stdin.readByte
      buffer := buffer.push nextByte
      byteCount := byteCount + 1

  -- Attempt to decode the buffer as UTF-8
  try
    let charStr ← String.fromUTF8! buffer
    if charStr.length == 1 then
      let c := charStr.get! 0
      return c.toNat -- Return Unicode codepoint
    else
      -- Should not happen if decoding is correct and we read the right number of bytes
      return 0xFFFD -- Replacement character on error
  catch e =>
    -- UTF-8 decoding error
    return 0xFFFD -- Replacement character

-- Export this function so it can be used by TerminalEnv
def readUtf8Char : IO Int := readUtf8CharIO

end Pakila.Core.CharReader
