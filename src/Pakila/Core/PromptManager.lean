import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.DigitalTwin
import Pakila.Diagnostics.SysInfo

open Lyceum

--TEMP_MARKER--

namespace Pakila

open Pakila.Core.DigitalTwin

/-- プロンプト管理ロジック -/
structure PromptManager where
  systemPromptTemplate : String := "あなたは優れたAIアシスタントです。\n\n[SRP 必須フォーマット]\n必ず以下のセクション形式(SRP)で出力すること:\n[Topic Model]: (現在のトピック)\n[Strategic Intent]: (直近の意図)\nBody: (本文・マークダウン)\n[Summary]: (まとめ)\n[Status]: (状態)"
deriving Repr, Inhabited

/-- システム情報、シンボリックステート、および外部コンテキストを初期プロンプトに注入する -/
def PromptManager.injectInitState (self : PromptManager) (info : SystemInfo) (loadedContext : String) (pattern : ProjectPattern) : String :=
  let symbolicState := "@CTX:[DOM:SYSTEM_ROOT|GOAL:INITIALIZED]\n@BIAS:{P:1.0, M:1.0, S:1.0, D:1.0, C:1.0}\nCONCEPT: [[READY]] [[ENV_LOADED]]"
  s!"{self.systemPromptTemplate}\n\n{loadedContext}\n\n{pattern.toInstruction}\n\n{symbolicState}\n\n--- Runtime Specs ---\n{formatSystemInfo info}\n--------------------\n"

/-- コンテキスト制限を管理する (古いメッセージを削除) -/
def PromptManager.manageContext (_self : PromptManager) (history : List Message) (maxMessages : Nat) : List Message :=
  if history.length > maxMessages then
    history.drop (history.length - maxMessages)
  else
    history

end Pakila
