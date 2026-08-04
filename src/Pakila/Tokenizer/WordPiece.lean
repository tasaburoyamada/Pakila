import Pakila.Tokenizer.Vocab

namespace Pakila.Tokenizer

/--
WordPiece トークナイズ (最適化版)。
BERT などのモデルで使用される最長前方一致アルゴリズム。
`Array Nat` バッファリングと `String.Pos` を用いたスライスにより、
無駄な List<->String 変換と O(N^3) 再割り当てを完全に排除。
-/
def wordPieceTokenize (v : Vocab) (text : String) : List Nat := Id.run do
  let words := text.splitOn " "
  let mut allTokens : Array Nat := #[]
  let unkId := v.getId "[UNK]" |>.getD 100

  for word in words do
    if word.isEmpty then continue
    
    if let some id := v.getId word then
      allTokens := allTokens.push id
      continue

    let mut startPos : String.Pos := 0
    let endPos : String.Pos := word.endPos
    let mut wordTokens : Array Nat := #[]
    let mut isBad := false

    while startPos < endPos do
      let mut curEnd : String.Pos := endPos
      let mut curTokenId : Option Nat := none
      let mut matchedEnd : String.Pos := startPos

      while curEnd > startPos do
        let rawSub := word.extract startPos curEnd
        let sub := if wordTokens.isEmpty then rawSub else "##" ++ rawSub
        if let some id := v.getId sub then
          curTokenId := some id
          matchedEnd := curEnd
          break
        curEnd := word.prev curEnd

      match curTokenId with
      | some id =>
          wordTokens := wordTokens.push id
          startPos := matchedEnd
      | none =>
          isBad := true
          break

    if isBad then
      allTokens := allTokens.push unkId
    else
      allTokens := allTokens.append wordTokens

  return allTokens.toList

end Pakila.Tokenizer
