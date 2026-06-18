import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.Theme
import Pakila.Core.Environment

open Lyceum

--TEMP_MARKER--

namespace Pakila.CLI.AuthUI

open Pakila

/-- 
認証UIのメインフロー。
ログイン失敗時に自動的にブラウザを起動し、ユーザーを導く。
TerminalEnv を介して抽象化されているため、テスト環境でも実環境でも動作する。
-/
def triggerAuthFlow {m : Type → Type} [Monad m] [TerminalEnv m] : m (Option String) := do
  TerminalEnv.println "\n"
  TerminalEnv.println (applyColor Color.magenta "╔══════════════════════════════════════════════════════════════════════════════╗")
  TerminalEnv.println (applyColor Color.magenta "║                 AUTHENTICATION REQUIRED: OPENING BROWSER...                  ║")
  TerminalEnv.println (applyColor Color.magenta "╚══════════════════════════════════════════════════════════════════════════════╝")
  TerminalEnv.println ""
  TerminalEnv.println "  [SYSTEM] 認証に失敗したか、API キーが設定されていません。"
  TerminalEnv.println "  Google AI Studio の認証ページをブラウザで起動します。"
  TerminalEnv.println ""
  
  let authUrl := "https://aistudio.google.com/app/apikey"
  TerminalEnv.println (applyColor Color.cyan s!"  Target URL: {authUrl}")
  TerminalEnv.println "  ----------------------------------------------------------------------------"
  
  -- 自動的にブラウザを開く (仮想/物理環境)
  TerminalEnv.println "  [ACTION] ブラウザを起動中..."
  let spawned ← TerminalEnv.spawnBrowser authUrl
  if !spawned then
    TerminalEnv.println (applyColor Color.yellow "  [Notice] 自動起動に失敗しました。上記URLを直接開いてください。")
  
  TerminalEnv.println ""
  TerminalEnv.println "  [GUIDE] 1. ブラウザで新しい API キーを作成、または既存のものをコピーしてください。"
  TerminalEnv.println "  [GUIDE] 2. 下記のプロンプトにコピーしたキーを貼り付けて Enter を押してください。"
  TerminalEnv.println ""
  
  TerminalEnv.print (applyColor Color.yellow "  Key > ")
  
  let key ← TerminalEnv.readLine
  let key := key.trimAscii.toString
  
  if key.isEmpty then
    TerminalEnv.println (applyColor Color.red "\n  [ABORT] API キーが入力されませんでした。処理を中断します。")
    return none
  else
    TerminalEnv.println (applyColor Color.green s!"\n  [SUCCESS] 新しい認証情報を適用しました。")
    return some key

end Pakila.CLI.AuthUI
