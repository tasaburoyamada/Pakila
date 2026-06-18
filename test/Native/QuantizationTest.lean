import Lyceum.Types
import Lyceum.Inference
import Pakila.Memory.Native

open Lyceum

--TEMP_MARKER--

namespace Pakila.Test.Native

/--
テスト用の物理データ生成
-/
def createDummyQ80Data : IO (ByteArray × ByteArray × Float) := do
  -- 期待される結果を計算
  -- 1ブロック分
  -- 計算: (2 * 3 * 32) * (0.5 * 2.0) = 6 * 32 * 1.0 = 192.0
  let expected := 192.0
  
  -- 手動でバイナリを構築 (C側の block_q8_0 に合わせる)
  -- typedef struct { float d; int8_t qs[32]; } block_q8_0;
  let mut ba1 := ByteArray.empty
  let mut ba2 := ByteArray.empty
  
  -- Block 1
  -- float 0.5 (little endian: 00 00 00 3f)
  ba1 := ba1.push 0x00
  ba1 := ba1.push 0x00
  ba1 := ba1.push 0x00
  ba1 := ba1.push 0x3f
  for _ in [0:32] do 
    ba1 := ba1.push 2
  
  -- Block 2
  -- float 2.0 (little endian: 00 00 00 40)
  ba2 := ba2.push 0x00
  ba2 := ba2.push 0x00
  ba2 := ba2.push 0x00
  ba2 := ba2.push 0x40
  for _ in [0:32] do 
    ba2 := ba2.push 3
  
  return (ba1, ba2, expected)

def testNativeQ80DotProduct : IO UInt32 := do
  IO.println "--- Test: Native AVX-512 Q8_0 Dot Product ---"
  let (ba1, ba2, expected) ← createDummyQ80Data
  
  let actual := Pakila.Memory.Native.dotProductQ80Native ba1 ba2
  
  if (actual - expected).abs < 0.0001 then
    IO.println s!"  [PASS] Expected: {expected}, Actual: {actual}"
    return 0
  else
    IO.println s!"  [FAIL] Expected: {expected}, Actual: {actual}"
    return 1

end Pakila.Test.Native
