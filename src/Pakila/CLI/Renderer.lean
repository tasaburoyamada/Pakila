import Lean.Data.Json



import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.Theme
import Pakila.Plugins.CodeExtractor
import Pakila.Protocol.Types -- StructuredLlmResponse のため
import Pakila.Core.Environment -- TerminalEnv のため


open Lyceum
open Lean.Json -- toJson を使えるように追加


--TEMP_MARKER--

namespace Pakila

open Lean hiding Message
open Pakila.Protocol

/-- JSON レンダリング用構造体 -/
structure JsonOutput where
  role : Role
  content : String
  toolCalls : List ToolCall := []
  status : Option String := none
deriving ToJson, FromJson

/--
Gemini CLI 模倣の角丸ボックス描画
-/
def renderNoticeBox (text : String) : String := Id.run do
  let lines := text.splitOn "\n"
  let width := lines.foldl (fun acc l => max acc l.length) 0 + 2
  let top := applyColor ProfessionalColors.lightYellow ("╭" ++ String.intercalate "" (List.replicate width "─") ++ "╮")
  let bottom := applyColor ProfessionalColors.lightYellow ("╰" ++ String.intercalate "" (List.replicate width "─") ++ "╯")
  let middle := lines.foldl (fun acc l =>
    let padding := String.intercalate "" (List.replicate (width - l.length - 1) " ")
    acc ++ applyColor ProfessionalColors.lightYellow "│" ++ " " ++ l ++ padding ++ applyColor ProfessionalColors.lightYellow "│" ++ "\n"
  ) ""
  return top ++ "\n" ++ middle ++ bottom

/-- 汎用グラフィカル・カードビュー描画 (2-C) - 端末幅への動的適応付き -/
def renderCardBox (title : String) (body : String) (color : Color := ProfessionalColors.cyan) (termWidth : Nat := 80) : String := Id.run do
  let maxBoxWidth := max 40 (min termWidth 120)
  let lines := body.splitOn "\n"
  let maxContentLen := lines.foldl (fun acc l => max acc l.length) title.length
  let contentWidth := min (maxBoxWidth - 4) (max maxContentLen title.length)
  let topBar := "╭─ " ++ title ++ " " ++ String.intercalate "" (List.replicate (max 0 (contentWidth - title.length)) "─") ++ "╮"
  let bottomBar := "╰" ++ String.intercalate "" (List.replicate (contentWidth + 4) "─") ++ "╯"
  let middle := lines.foldl (fun acc l =>
    let trimmedLine := if l.length > contentWidth then (l.take (contentWidth - 3)).toString ++ "..." else l
    let padLen := max 0 (contentWidth - trimmedLine.length + 2)
    let padding := String.intercalate "" (List.replicate padLen " ")
    acc ++ applyColor color "│" ++ " " ++ trimmedLine ++ padding ++ applyColor color "│" ++ "\n"
  ) ""
  return applyColor color topBar ++ "\n" ++ middle ++ applyColor color bottomBar

/-- エラー表示用カード（1-A, 1-B 構造化エラー・サジェスチョン・ヒント統合） -/
def renderErrorBox (errTitle : String) (errMsg : String) (suggestion : Option String := none) (similarCmds : List String := []) (termWidth : Nat := 80) : String := Id.run do
  let mut content := errMsg
  if let some sug := suggestion then
    content := content ++ "\n\n" ++ applyBold (applyColor Color.yellow "💡 解決のヒント:") ++ "\n  " ++ sug
  if !similarCmds.isEmpty then
    content := content ++ "\n\n" ++ applyBold (applyColor Color.cyan "🔍 もしかして:") ++ "\n"
    for cmd in similarCmds do
      content := content ++ s!"  • pakila {cmd}\n"
  return renderCardBox s!"ERROR: {errTitle}" content Color.red termWidth

/-- プロフェッショナルなマークダウンレンダラー -/
def renderMarkdown (text : String) : String := Id.run do
  let lines := text.splitOn "\n"
  let mut inCode := false
  let mut res := ""
  for line in lines do
    let trimmed := line.trimAscii.toString
    if trimmed.startsWith "```" then
      if inCode then
        res := res ++ applyColor ProfessionalColors.gray "╰" ++ String.intercalate "" (List.replicate 60 "─") ++ "\n"
        inCode := false
      else
        let lang := trimmed.drop 3 |>.trimAscii.toString
        res := res ++ applyColor ProfessionalColors.gray s!"╭─── {lang} " ++ String.intercalate "" (List.replicate (54 - lang.length) "─") ++ "\n"
        inCode := true
    else
      if inCode then
        res := res ++ applyColor ProfessionalColors.gray "│ " ++ line ++ "\n"
      else
        let mut l := line
        -- Bold
        if containsSubstr l "**" then
          let parts := l.splitOn "**"
          let mut boldLine := ""
          let mut isBold := false
          for p in parts do
            if isBold then
              boldLine := boldLine ++ applyBold (applyColor ProfessionalColors.brightWhite p)
              isBold := false
            else
              boldLine := boldLine ++ p
              isBold := true
          l := boldLine

        -- List
        if l.startsWith "- " || l.startsWith "* " then
          l := "  \x1b[32m•\x1b[0m " ++ (l.drop 2).toString

        -- Quote
        if l.startsWith "> " then
          l := applyColor (.xterm 244) "┃ " ++ (l.drop 2).toString

        -- Table
        if l.startsWith "|" then
          l := l.replace "|" (applyColor ProfessionalColors.gray "│")
          l := l.replace "-" (applyColor ProfessionalColors.gray "─")

        -- Diff-style
        if l.startsWith "+ " then
          l := applyColor Color.green l
        else if l.startsWith "- " then
          l := applyColor Color.red l

        res := res ++ l ++ "\n"
  return res.trimAscii.toString

/-- ステータス行のレンダリング -/
def renderStatus (model : String) (duration : Float) : String :=
  "\n" ++ applyColor ProfessionalColors.gray s!"[ {model} | {duration.toString.take 3}s ]" ++ "\n"

/-- メッセージ全体をレンダリングする -/
def renderMessage (msg : Message) (model : String := "Gemini") (duration : Float := 0.0) : String := Id.run do
  let mut output := ""

  -- Role Header (Optional, for clarity)
  let roleHeader := match msg.role with
    | .user => applyColor Color.cyan "❯ User"
    | .assistant => applyColor Color.green "❯ AI"
    | .system => applyColor Color.yellow "❯ System"
    | .tool => applyColor ProfessionalColors.gray "❯ Tool"

  output := output ++ roleHeader ++ "\n"

  for part in msg.parts do
    match part with
    | .text t => output := output ++ renderMarkdown t ++ "\n"
    | .image mime data => output := output ++ applyColor Color.yellow s!"[IMAGE: {mime} ({data.size} bytes)]\n"
    | .toolCall c =>
        output := output ++ applyColor ProfessionalColors.gray s!"▶ {c.function.name.toUpper}" ++
                  applyColor Color.default s!"({c.function.arguments})\n"
    | .toolResponse id _ =>
        output := output ++ applyColor Color.green s!"✔ {id} RETURNED SUCCESS\n"
    | _ => pure ()

  if !output.isEmpty then
    output := output ++ renderStatus model duration
  return output.trimAscii.toString

/-- メッセージを JSON 形式でレンダリングする -/
def renderMessageJson (msg : Message) (model : String := "Gemini") (duration : Float := 0.0) : Json :=
  let content := msg.parts.foldl (fun acc p => match p with | .text t => acc ++ t | _ => acc) ""
  let toolCalls := msg.parts.filterMap (fun p => match p with | .toolCall c => some c | _ => none)
  let status := s!"[Status: {model} | {duration.toString.take 3}s]"
  toJson ({ role := msg.role, content := content, toolCalls := toolCalls, status := some status } : JsonOutput)

/-- 現在のTopicヘッダーをレンダリングする -/
def renderTopicHeader (topic : String) : String :=
  "\n" ++ applyColor Color.blue s!"[ Active Topic: {topic} ]" ++ "\n"

/-- メッセージを効率的に結合 -/
def renderMessageParts (parts : List MessagePart) : String :=
  parts.map (fun p => match p with | .text t => t | _ => "") |> String.join

/-- === 構造化コンソール用の新しいレンダリング関数 === -/

def renderUserTurn (input : String) : IO Unit := do

  TerminalEnv.println (s!"\n" ++ (String.intercalate "" (List.replicate 80 "─")))
  TerminalEnv.println (applyColor .cyan s!"[User]")
  TerminalEnv.println (applyColor .default s!"User > {input}")
  TerminalEnv.println (String.intercalate "" (List.replicate 80 "─"))

def renderAiThinking (thought : String) : IO Unit := do

  TerminalEnv.println (s!"\n" ++ (String.intercalate "" (List.replicate 80 "─")))
  TerminalEnv.println (applyColor .green s!"[AI: Thinking]")
  TerminalEnv.println (renderMarkdown thought)

def renderAiAction (action : String) : IO Unit := do

  TerminalEnv.println (applyColor .yellow s!"[AI: Action]")
  TerminalEnv.println (applyColor .yellow s!"```bash\n{action}\n```")
  TerminalEnv.println (applyColor .yellow "[実行中...]")

def renderSystemOutput (output : String) : IO Unit := do

  TerminalEnv.println (applyColor ProfessionalColors.gray s!"[System: Output]")
  TerminalEnv.println output
  TerminalEnv.println (applyColor ProfessionalColors.gray "[完了]")

def renderAiResponse (response : String) : IO Unit := do

  TerminalEnv.println (applyColor .green s!"[AI: Response]")
  TerminalEnv.println (renderMarkdown response)
  TerminalEnv.println (String.intercalate "" (List.replicate 80 "─"))

end Pakila
