import Pakila.Protocol.Types
import Lean.Data.Json

namespace Pakila.Protocol

/-- LLMの応答を機械的にMachineActionへ変換する (SRP: Structured Response Parsing) -/
def parseSrp (rawText : String) : MachineAction :=
  -- NOTE: 本来は複雑な文字列解析が必要。最初はプロトタイプとして単純な形式を想定。
  -- 例: "/bash ls" -> MachineAction.ExecuteBash "ls"
  if rawText.startsWith "/bash " then
    .ExecuteBash (rawText.drop 6).trimAscii.toString
  else if rawText.startsWith "/write " then
    -- "/write path content" を想定した単純分割
    let parts := rawText.splitOn " "
    if parts.length >= 3 then
      .WriteFile parts[1]! (String.intercalate " " (parts.drop 2))
    else .CallLlm []
  else if rawText.contains "Quit" then
    .Quit
  else
    .CallLlm []

end Pakila.Protocol
