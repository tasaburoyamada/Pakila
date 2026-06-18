import pty, os, time, sys
master, slave = pty.openpty()
pid = os.fork()
if pid == 0:
    os.setsid()
    os.dup2(slave, 0)
    os.dup2(slave, 1)
    os.dup2(slave, 2)
    os.close(master)
    os.close(slave)
    os.environ["PATH"] = os.environ["PATH"]
    os.execvp("gemini", ["gemini", "-p", "Execute 'ls -l'"])
else:
    os.close(slave)
    time.sleep(4)
    output = os.read(master, 8192).decode()
    print("--- TOOL EXECUTION UX ---")
    print(repr(output))
    os.kill(pid, 9)
