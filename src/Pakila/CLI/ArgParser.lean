import Lyceum.Types
import Lyceum.Inference
import Pakila.CLI.Args

open Lyceum

namespace Pakila

def stringToApprovalMode (s : String) : Option ApprovalMode :=
  match s with
  | "default" => some .default
  | "auto_edit" => some .auto_edit
  | "yolo" => some .yolo
  | "plan" => some .plan
  | _ => none

def stringToOutputFormat (s : String) : Option OutputFormat :=
  match s with
  | "text" => some .text
  | "json" => some .json
  | "stream-json" => some .streamJson
  | _ => none

/-- CLI 引数のパースロジック -/
def parseCliArgs (args : List String) : Except AppError Subcommand :=
  let rec parseRunArgs (args : List String) (acc : RunArgs) : Except AppError Subcommand :=
    match args with
    | [] => return Subcommand.run { acc with policies := acc.policies.reverse, query := acc.query.reverse }
    | "-m" :: m :: rest | "--model" :: m :: rest => parseRunArgs rest { acc with model := some m }
    | "-p" :: p :: rest | "--prompt" :: p :: rest => parseRunArgs rest { acc with prompt := some p }
    | "-i" :: p :: rest | "--prompt-interactive" :: p :: rest => parseRunArgs rest { acc with promptInteractive := some p }
    | "-y" :: rest | "--yolo" :: rest => parseRunArgs rest { acc with approvalMode := .yolo }
    | "-r" :: s :: rest | "--resume" :: s :: rest => parseRunArgs rest { acc with session := some s }
    | "-w" :: s :: rest | "--worktree" :: s :: rest => parseRunArgs rest { acc with worktree := some s }
    | "-s" :: rest | "--sandbox" :: rest => parseRunArgs rest { acc with sandbox := true }
    | "--approval-mode" :: m :: rest => 
        match stringToApprovalMode m with
        | some am => parseRunArgs rest { acc with approvalMode := am }
        | none => Except.error (AppError.ConfigError s!"Invalid approval mode: {m}")
    | "--output-format" :: f :: rest | "-o" :: f :: rest =>
        match stringToOutputFormat f with
        | some fmt => parseRunArgs rest { acc with outputFormat := fmt }
        | none => Except.error (AppError.ConfigError s!"Invalid output format: {f}")
    | "--policy" :: p :: rest => parseRunArgs rest { acc with policies := p :: acc.policies }
    | "--skip-trust" :: rest => parseRunArgs rest { acc with skipTrust := true }
    | "-h" :: _ | "--help" :: _ => return Subcommand.help
    | "-v" :: _ | "--version" :: _ => return Subcommand.version
    | q :: rest => parseRunArgs rest { acc with query := q :: acc.query }

  match args with
  | [] => return Subcommand.run {}
  | "mcp" :: rest => return Subcommand.mcp rest
  | "skills" :: rest | "skill" :: rest => return Subcommand.skills rest
  | "hooks" :: rest | "hook" :: rest => return Subcommand.hooks rest
  | "config" :: _ => return Subcommand.config
  | "session" :: name :: _ => return Subcommand.session name
  | "--list-sessions" :: _ => return Subcommand.listSessions
  | "--delete-session" :: name :: _ => return Subcommand.deleteSession name
  | "--list-extensions" :: _ | "-l" :: _ => return Subcommand.listExtensions
  | "-h" :: _ | "--help" :: _ => return Subcommand.help
  | "-v" :: _ | "--version" :: _ => return Subcommand.version
  | "run" :: rest => parseRunArgs rest {}
  | other => parseRunArgs other {}

end Pakila
