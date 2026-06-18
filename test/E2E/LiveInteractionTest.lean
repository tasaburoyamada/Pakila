import Lean
import Lean.Data.Json
import Lyceum.Types
import Lyceum.Inference

open Lyceum

--TEMP_MARKER--

namespace Pakila.Test

open Lean hiding Message

def fetchActiveModel (apiKey : String) : IO String := do
  if let some m ← IO.getEnv "PAKILA_MODEL" then
    return m
  
  IO.println "  [ACTION] Fetching available models dynamically from API..."
  let child ← IO.Process.spawn {
    cmd := "curl",
    args := #["-s", "-H", s!"x-goog-api-key: {apiKey}", s!"https://generativelanguage.googleapis.com/v1beta/models?key={apiKey}"],
    stdout := .piped
  }
  let out ← child.stdout.readToEnd
  let _ ← child.wait
  
  match Json.parse out with
  | .ok json =>
      if let .ok modelsArr := json.getObjVal? "models" then
        if let .ok arr := modelsArr.getArr? then
          for j in arr do
            if let .ok (.str name) := j.getObjVal? "name" then
              if name.contains "gemini" && !name.contains "embedding" && !name.contains "tts" then
                let modelName := name.replace "models/" ""
                IO.println s!"  [PASS] Dynamically selected model: {modelName}"
                return modelName
  | _ => pure ()
  IO.println "  [FAIL] Could not dynamically fetch a valid model."
  return ""

def runLiveInteractionTest : IO UInt32 := do
  IO.println "Running test: Live Native E2E Interaction (Real API)..."
  
  -- 本物のAPIキーを取得
  let realApiKey ← match ← IO.getEnv "GOOGLE_API_KEY" with
    | some k => pure k
    | none => 
      match ← IO.getEnv "GEMINI_API_KEY" with
      | some k => pure k
      | none =>
          IO.println "  [SKIPPED] No real API key found."
          return 0
          
  let modelToUse ← fetchActiveModel realApiKey
  if modelToUse.isEmpty then return 1
  
  let mut envVars : Array (String × Option String) := #[]
  envVars := envVars.push ("GOOGLE_API_KEY", none)
  envVars := envVars.push ("GEMINI_API_KEY", none)
  envVars := envVars.push ("PAKILA_API_URL", none)
  envVars := envVars.push ("PAKILA_MODEL", some modelToUse)
      
  let pakilaBin := "./.lake/build/bin/pakila"
  if !(← System.FilePath.mk pakilaBin |>.pathExists) then
    IO.println "  [FAIL] pakila binary not found."
    return 1

  IO.println "  [ACTION] Spawning pakila subprocess..."
  let mut child ← IO.Process.spawn {
    cmd := pakilaBin,
    args := #["run"],
    env := envVars,
    stdin := .piped,
    stdout := .piped,
    stderr := .piped
  }
  
  let stdin := child.stdin
  let stdout := child.stdout
  
  let expect (target : String) (timeoutMs : Nat) : IO Bool := do
    let start ← IO.monoMsNow
    let mut acc := ""
    while (← IO.monoMsNow) - start < timeoutMs do
      let buf ← stdout.read 1
      if !buf.isEmpty then
        let c := Char.ofNat buf[0]!.toNat
        acc := acc.push c
        if acc.contains target then return true
      IO.sleep 10
    IO.println s!"\n  [Timeout] Expected '{target}' but timed out ({timeoutMs}ms)."
    return false

  -- 1. Key prompt を待つ (30s SLA: 起動コスト)
  if ← expect "Key >" 30000 then
    IO.println "  [PASS] Key prompt detected."
    stdin.putStrLn realApiKey; stdin.flush
  else return 1
  
  -- 2. User prompt を待つ (30s SLA: 起動コスト)
  if ← expect "User >" 30000 then
    IO.println "  [PASS] Main prompt detected."
    stdin.putStrLn "Hello. Respond exactly with the word: LIVE_SUCCESS"; stdin.flush
  else return 1

  -- 3. AI response を待つ (2s SLA: 厳格な推論SLA)
  if ← expect "LIVE_SUCCESS" 2000 then
    IO.println "  [PASS] Received LIVE_SUCCESS within SLA."
  else return 1
      
  stdin.putStrLn "exit"; stdin.flush
  let _ ← child.wait
  return 0

end Pakila.Test
