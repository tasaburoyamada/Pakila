import Pakila.Tokenizer.Unigram

open Pakila.Tokenizer

/-- 日本語正規化ロジックのテスト -/
def runJapaneseTokenizerTest : IO Unit := do
  IO.println "==============================================="
  IO.println "   PAKILA JAPANESE TOKENIZER TEST   "
  IO.println "==============================================="

  let test1 := "Ｈｅｌｌｏ　Ｗｏｒｌｄ１２３"
  let expected1 := "Hello World123"
  let res1 := normalizeJapanese test1
  
  if res1 == expected1 then
    IO.println "  ✔ SUCCESS: Full-width alphanumeric and space normalization."
  else
    IO.println s!"  ✖ FAILURE: Expected '{expected1}', got '{res1}'"

  let test2 := "正規化テスト！"
  let expected2 := "正規化テスト!"
  let res2 := normalizeJapanese test2
  
  if res2 == expected2 then
    IO.println "  ✔ SUCCESS: Full-width punctuation normalization."
  else
    IO.println s!"  ✖ FAILURE: Expected '{expected2}', got '{res2}'"

  IO.println "==============================================="
  IO.println "   TOKENIZER TEST COMPLETE   "
  IO.println "==============================================="

def main : IO Unit := runJapaneseTokenizerTest