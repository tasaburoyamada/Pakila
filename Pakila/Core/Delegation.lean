import Pakila.Core.Interface
import Pakila.Protocol.Types
import Pakila.Core.Types
import Lyceum.Types
import Lyceum.Inference
import Pakila.Core.Delegator
import Pakila.Core.State
import Pakila.CLI.Theme

open Lyceum
open Pakila
open Pakila.Protocol
open Pakila.Core.Delegator

namespace Pakila

/-- エージェント（サブプロセス）を呼び出すスタブ実装 -/
def invokeAgent (req : AgentRequest) : IO (Except String String) := do
  pure (.ok s!"Agent {(toString (repr req.type))} finished task.")

/-- エージェント委譲アクションを処理する -/
def handleInvokeAgent (cont : Continuation IO) (config : AppConfig) (client : LlmInstance) (modelName : String) (s : InterpreterState) (nextS : InterpreterState) (req : AgentRequest) : IO Unit := do
  TerminalEnv.print (applyColor .cyan s!"▶ DELEGATE: Invoking {(toString (repr req.type))}...\n")
  TerminalEnv.print (applyColor .cyan s!"▶ DELEGATE: Invoking {(toString (repr req.type))}...\n")
  
  -- Construct the Python script content to call the tool.
  -- The AgentRequest object needs to be passed as a JSON string argument.
  let python_script_content := '''import default_api
import json
import sys

# Argument is an AgentRequest object, passed as a JSON string.
agent_request_json = sys.argv[1]

try:
    agent_request = json.loads(agent_request_json)
    
    # Call the available tool.
    # Parameters: agent_name, prompt, wait_for_previous
    # Assuming AgentRequest has fields: agent_name, prompt, and optionally wait_for_previous.
    tool_output = default_api.invoke_agent(
        agent_name=agent_request['agent_name'],
        prompt=agent_request['prompt'],
        wait_for_previous=agent_request.get('wait_for_previous', False) # Use .get for optional field
    )
    
    # Convert the tool's dictionary output to a JSON string.
    print(json.dumps(tool_output))

except Exception as e:
    error_message = f"Error executing invoke_agent: {e}"
    print(error_message)
    sys.exit(1)'''
  -- Serialize the AgentRequest object itself into a JSON string so it can be safely embedded into the command string.
  -- This requires that the AgentRequest type in Lean is serializable to JSON.
  -- Assuming `req` has a `ToJson` instance.
  let agent_request_json_arg := json.dumps(req) -- This assumes `req` can be serialized.
  
  -- Serialize the Python script content itself.
  let escaped_python_script := json.dumps(python_script_content)

  -- Construct the full command to run. Arguments are passed as JSON strings.
  let command_to_run := s!"python -c {escaped_python_script} {agent_request_json_arg}"
  
  -- Execute the command using the agent's shell command tool.
  let result ← runAgentShellCommand(
      command := command_to_run,
      description := "Invoke sub-agent",
      dir_path := "/home/pc241139/sandbox/kaihatsu/apps/pakila/"
  )

  -- Process the result.
  let output_str := result.output.get_or_else "Error: No output from shell command."
  let exit_code := result.exit_code.get_or_else 1 -- Default to error code if exit_code is None

  -- Format the tool message based on success or failure.
  let toolMsg : Message := 
    if exit_code == 0 then
      { role := .tool, parts := [.toolResponse "invoke_agent" output_str] }
    else
      { role := .tool, parts := [.toolResponse "invoke_agent" s!"Error: {output_str}"] }

  -- Update the state and continue the loop.
  let finalS : InterpreterState := { nextS with history := nextS.history ++ [toolMsg] }
  cont.runLoop nextS

end Pakila
