import pty, os, time, sys

# Japanese input to test
japanese_input = "こんにちは"
# Command to run Pakila's interactive CLI
pakila_command = ["lake", "run", "Main"]

# Create a pseudo-terminal
master_fd, slave_fd = pty.openpty()

pid = os.fork()

if pid == 0:
    # Child process
    os.setsid()
    os.dup2(slave_fd, 0)  # stdin
    os.dup2(slave_fd, 1)  # stdout
    os.dup2(slave_fd, 2)  # stderr
    os.close(master_fd)
    os.close(slave_fd)

    try:
        os.execvp(pakila_command[0], pakila_command)
    except FileNotFoundError:
        print(f"Error: Command '{pakila_command[0]}' not found. Ensure 'lake' is in your PATH.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error during os.execvp: {e}", file=sys.stderr)
        sys.exit(1)
else:
    # Parent process
    os.close(slave_fd)

    time.sleep(2)  # Wait a moment for the Pakila process to start and display the prompt

    try:
        # Send the Japanese input followed by a newline
        newline_char = '
'
        input_data = (japanese_input + newline_char).encode('utf-8')
        os.write(master_fd, input_data)
        print(f"Sent input: {japanese_input}
")

        # Wait a bit for the input to be processed and output to be generated
        time.sleep(2) # Give some time for the process to generate output after input

        # Read the output from the pseudo-terminal
        output_bytes = b''
        try:
            output_bytes = os.read(master_fd, 8192) # Read up to 8192 bytes
        except Exception as e:
            print(f"Error reading from master_fd: {e}", file=sys.stderr)

        output_str = output_bytes.decode('utf-8', errors='replace') # Use replace for decoding errors

        print("---" * 10 + " Pakila CLI Output " + "---" * 10)
        print(repr(output_str))

        if japanese_input in output_str:
            print("Verification SUCCESS: Japanese input appears to be processed correctly.")
        else:
            print("Verification FAILED: Japanese input not found in the output. The fix might not be working as expected.")
            sys.exit(1) # Indicate test failure

    except Exception as e:
        print(f"An error occurred in the parent process: {e}", file=sys.stderr)
        sys.exit(1) # Indicate test failure
    finally:
        # Clean up the process
        try:
            os.kill(pid, 9) # Send SIGKILL to terminate the child process
            os.waitpid(pid, 0) # Wait for the process to be reaped
        except ProcessLookupError:
            pass # Process already terminated
        except Exception as e:
            print(f"Error during cleanup: {e}", file=sys.stderr)
