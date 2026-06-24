import Pakila.Core.Interface
import Pakila.Protocol.Types
import Pakila.Core.Types
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.State
import Pakila.CLI.Theme

open Lyceum
open Pakila
open Pakila.Protocol

namespace Pakila

/-- 画像編集アクションを処理する -/
def handleEditImage (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (file : String) (prompt : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ EDIT_IMAGE: {file} ({prompt})...\n")
  TerminalEnv.print (applyColor .cyan s!"▶ EDIT_IMAGE: {file} ({prompt})...\n")
  
  -- Construct the Python script content to call the tool.
  let python_script_content := '''import default_api
import json
import sys

# Arguments received from Lean code, passed as JSON strings via command line args.
file_arg_json = sys.argv[1]
prompt_arg_json = sys.argv[2]

try:
    file_arg = json.loads(file_arg_json)
    prompt_arg = json.loads(prompt_arg_json)
    
    # Call the available tool.
    tool_output = default_api.mcp_nanobanana_edit_image(
        file=file_arg, 
        prompt=prompt_arg, 
        preview=False, 
        wait_for_previous=True
    )
    
    # Convert the tool's dictionary output to a JSON string.
    print(json.dumps(tool_output))

except Exception as e:
    error_message = f"Error executing mcp_nanobanana_edit_image: {e}"
    print(error_message)
    sys.exit(1)'''
  -- Serialize the Python script content itself into a JSON string so it can be safely embedded into the command string.
  let escaped_python_script := json.dumps(python_script_content)

  -- Construct the full command to run. Arguments are passed as JSON strings.
  let command_to_run := s!"python -c {escaped_python_script} {json.dumps(file)} {json.dumps(prompt)}"
  
  -- Execute the command using the agent's shell command tool.
  -- We assume a Lean function `runAgentShellCommand` exists that bridges to agent's `default_api.run_shell_command`.
  -- This function should return a structure like {'output': str, 'exit_code': int | None}.
  let result ← runAgentShellCommand(
      command := command_to_run,
      description := "Edit image using Nano Banana tool",
      dir_path := "/home/pc241139/sandbox/kaihatsu/apps/pakila/"
  )

  -- Process the result.
  let output_str := result.output.get_or_else "Error: No output from shell command."
  let exit_code := result.exit_code.get_or_else 1 -- Default to error code if exit_code is None

  -- Format the tool message based on success or failure.
  let toolMsg : Message := 
    if exit_code == 0 then
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_edit_image" output_str] }
    else
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_edit_image" s!"Error: {output_str}"] }

  -- Update the state and continue the loop.
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

/-- 画像復元アクションを処理する -/
def handleRestoreImage (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (file : String) (prompt : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ RESTORE_IMAGE: {file}...\n")
  TerminalEnv.print (applyColor .cyan s!"▶ RESTORE_IMAGE: {file}...\n")
  
  -- Construct the Python script content to call the tool.
  let python_script_content := '''import default_api
import json
import sys

# Arguments received from Lean code, passed as JSON strings via command line args.
file_arg_json = sys.argv[1]
prompt_arg_json = sys.argv[2]

try:
    file_arg = json.loads(file_arg_json)
    prompt_arg = json.loads(prompt_arg_json)
    
    # Call the available tool.
    tool_output = default_api.mcp_nanobanana_restore_image(
        file=file_arg, 
        prompt=prompt_arg, 
        preview=False, 
        wait_for_previous=True
    )
    
    # Convert the tool's dictionary output to a JSON string.
    print(json.dumps(tool_output))

except Exception as e:
    error_message = f"Error executing mcp_nanobanana_restore_image: {e}"
    print(error_message)
    sys.exit(1)'''
  -- Serialize the Python script content itself into a JSON string so it can be safely embedded into the command string.
  let escaped_python_script := json.dumps(python_script_content)

  -- Construct the full command to run. Arguments are passed as JSON strings.
  let command_to_run := s!"python -c {escaped_python_script} {json.dumps(file)} {json.dumps(prompt)}"
  
  -- Execute the command using the agent's shell command tool.
  let result ← runAgentShellCommand(
      command := command_to_run,
      description := "Restore image using Nano Banana tool",
      dir_path := "/home/pc241139/sandbox/kaihatsu/apps/pakila/"
  )

  -- Process the result.
  let output_str := result.output.get_or_else "Error: No output from shell command."
  let exit_code := result.exit_code.get_or_else 1 -- Default to error code if exit_code is None

  -- Format the tool message based on success or failure.
  let toolMsg : Message := 
    if exit_code == 0 then
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_restore_image" output_str] }
    else
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_restore_image" s!"Error: {output_str}"] }

  -- Update the state and continue the loop.
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

/-- アイコン生成アクションを処理する -/
def handleGenerateIcon (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (prompt : String) (sizes : List Nat) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ ICON: {prompt}...\n")
  TerminalEnv.print (applyColor .cyan s!"▶ ICON: {prompt}...\n")
  
  -- Construct the Python script content to call the tool.
  let python_script_content := '''import default_api
import json
import sys

# Arguments received from Lean code, passed as JSON strings via command line args.
prompt_arg_json = sys.argv[1]
sizes_arg_json = sys.argv[2]

try:
    prompt_arg = json.loads(prompt_arg_json)
    sizes_arg = json.loads(sizes_arg_json)
    
    # Call the available tool.
    tool_output = default_api.mcp_nanobanana_generate_icon(
        prompt=prompt_arg, 
        sizes=sizes_arg, 
        preview=False, 
        wait_for_previous=True
    )
    
    # Convert the tool's dictionary output to a JSON string.
    print(json.dumps(tool_output))

except Exception as e:
    error_message = f"Error executing mcp_nanobanana_generate_icon: {e}"
    print(error_message)
    sys.exit(1)'''
  -- Serialize the Python script content itself into a JSON string so it can be safely embedded into the command string.
  let escaped_python_script := json.dumps(python_script_content)

  -- Construct the full command to run. Arguments are passed as JSON strings.
  let command_to_run := s!"python -c {escaped_python_script} {json.dumps(prompt)} {json.dumps(sizes)}"
  
  -- Execute the command using the agent's shell command tool.
  let result ← runAgentShellCommand(
      command := command_to_run,
      description := "Generate icon using Nano Banana tool",
      dir_path := "/home/pc241139/sandbox/kaihatsu/apps/pakila/"
  )

  -- Process the result.
  let output_str := result.output.get_or_else "Error: No output from shell command."
  let exit_code := result.exit_code.get_or_else 1 -- Default to error code if exit_code is None

  -- Format the tool message based on success or failure.
  let toolMsg : Message := 
    if exit_code == 0 then
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_icon" output_str] }
    else
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_icon" s!"Error: {output_str}"] }

  -- Update the state and continue the loop.
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

/-- 図生成アクションを処理する -/
def handleGenerateDiagram (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (prompt : String) (t : String) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ DIAGRAM: Generating {t} diagram...\n")
  TerminalEnv.print (applyColor .cyan s!"▶ DIAGRAM: Generating {t} diagram...\n")
  
  -- Construct the Python script content to call the tool.
  let python_script_content := '''import default_api
import json
import sys

# Arguments received from Lean code, passed as JSON strings via command line args.
prompt_arg_json = sys.argv[1]
type_arg_json = sys.argv[2]

try:
    prompt_arg = json.loads(prompt_arg_json)
    type_arg = json.loads(type_arg_json)
    
    # Call the available tool.
    tool_output = default_api.mcp_nanobanana_generate_diagram(
        prompt=prompt_arg, 
        type=type_arg, 
        preview=False, 
        wait_for_previous=True
    )
    
    # Convert the tool's dictionary output to a JSON string.
    print(json.dumps(tool_output))

except Exception as e:
    error_message = f"Error executing mcp_nanobanana_generate_diagram: {e}"
    print(error_message)
    sys.exit(1)'''
  -- Serialize the Python script content itself into a JSON string so it can be safely embedded into the command string.
  let escaped_python_script := json.dumps(python_script_content)

  -- Construct the full command to run. Arguments are passed as JSON strings.
  let command_to_run := s!"python -c {escaped_python_script} {json.dumps(prompt)} {json.dumps(t)}"
  
  -- Execute the command using the agent's shell command tool.
  let result ← runAgentShellCommand(
      command := command_to_run,
      description := "Generate diagram using Nano Banana tool",
      dir_path := "/home/pc241139/sandbox/kaihatsu/apps/pakila/"
  )

  -- Process the result.
  let output_str := result.output.get_or_else "Error: No output from shell command."
  let exit_code := result.exit_code.get_or_else 1 -- Default to error code if exit_code is None

  -- Format the tool message based on success or failure.
  let toolMsg : Message := 
    if exit_code == 0 then
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_diagram" output_str] }
    else
      { role := .tool, parts := [.toolResponse "mcp_nanobanana_generate_diagram" s!"Error: {output_str}"] }

  -- Update the state and continue the loop.
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

end Pakila
