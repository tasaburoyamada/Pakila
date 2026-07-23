namespace Pakila.Util.Unicode

/-- 文字の表示幅を計算 (簡易的な East Asian Width 実装) -/
def charWidth (c : Char) : Nat :=
  let code := c.toNat
  if code <= 0x1F then 0      -- 制御文字
  else if code <= 0x7E then 1  -- ASCII
  else if code <= 0xA0 then 1  -- その他
  else if code <= 0xFF then 1  -- Latin-1
  else if code <= 0x1100 then 1
  else if code <= 0x115F then 2 -- Hangul
  else if code <= 0x2329 then 1
  else if code == 0x232A then 1
  -- CJKの範囲を広くカバー
  else if code >= 0x2E80 && code <= 0x9FFF then 2 
  else if code >= 0xAC00 && code <= 0xD7A3 then 2
  else if code >= 0xF900 && code <= 0xFAFF then 2
  else 1

/-- 文字列全体の表示幅を計算 -/
def stringWidth (s : String) : Nat :=
  s.toList.foldl (fun acc c => acc + charWidth c) 0

end Pakila.Util.Unicode
