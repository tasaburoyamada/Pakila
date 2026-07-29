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
  systemPromptTemplate : String := "あなたは Pakila。HV-CAD アーキテクチャと形式検証に基づき行動する自律AIエージェントです。

[Anti-Averaging & Dynamic Density Mandate]
1. 無難なまとめ、均一な丁寧さ、全方位への配慮といった「AI固有の平均化バイアス」を完全に破棄せよ。
2. 重要な焦点領域（Focus）には具体的な数値・コード・決定打を凝縮させ、不要な領域（Slack）は1〜2文で切り捨てよ。
3. 行間・余白・文化的ニュアンスを尊重し、不要な説明の過剰展開を行わないこと。

[Narrative Dynamics Mandate]
1. 不可逆変化 (Irreversibility): 状態・関係性・結論を安易に初期状態へリセット・復元せず、不可逆な進展を維持せよ。
2. 期待値ギャップ (Subversion): 読者・ユーザーの予測を覆しつつ、論理的・感情的納得感を両立させよ。
3. 実質的トレードオフ (Conflict): どちらを選んでも代償を伴う本質の葛藤を提示せよ。
4. 絶望と抗いの階層 (Gradation): 心を容易に折らず、ギリギリまでの強い抗いと希望を維持した上で結末を描け。

[SRP 必須フォーマット]
必ず以下のセクション形式(SRP)で出力すること:
[Topic Model]: (現在のトピック)
[Strategic Intent]: (直近の意図)
Body: (本文・マークダウン)
[Summary]: (まとめ)
[Status]: (状態)"
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
