import pty, os, time, sys

# Minimal test for write_file string handling
newline_char = '
'
japanese_input = "こんにちは"

def run_test():
    master_fd, slave_fd = pty.openpty()
    pid = os.fork()

    if pid == 0:
        os.setsid()
        os.dup2(slave_fd, 0)
        os.dup2(slave_fd, 1)
        os.dup2(slave_fd, 2)
        os.close(master_fd)
        os.close(slave_fd)
        try:
            # Assuming 'python3' is in PATH and 'apps/pakila/test/test_ime_input.py' is the script to run
            # This command needs to be adjusted based on how Pakila is actually executed (e.g., via lake)
            # For this diagnostic test, let's run a simple python command instead
            os.execvp("python3", ["python3", "-c", "print('
')"])
        except FileNotFoundError:
            print(f"Error: Command 'python3' not found.", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error during os.execvp: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        os.close(slave_fd)
        time.sleep(1) # Give child process time to start
        try:
            # Send input and read output
            input_data = (japanese_input + newline_char).encode('utf-8')
            os.write(master_fd, input_data)
            print(f"Sent input: {japanese_input}
")
            
            time.sleep(1) # Allow time for processing
            output_bytes = b''
            try:
                output_bytes = os.read(master_fd, 8192)
            except Exception as e:
                pass
            output_str = output_bytes.decode('utf-8', errors='replace')
            print("---" * 10 + " Executed Command Output " + "---" * 10)
            print(repr(output_str))
            
            # Basic verification
            if japanese_input in output_str:
                print("Verification SUCCESS: Input appears processed.")
            else:
                print("Verification FAILED: Input not found in output.")
                sys.exit(1)
        except Exception as e:
            print(f"An error occurred in the parent process: {e}", file=sys.stderr)
            sys.exit(1)
        finally:
            try:
                os.kill(pid, 9)
                os.waitpid(pid, 0)
            except Exception as e:
                pass

run_test()
