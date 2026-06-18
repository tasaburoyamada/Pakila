import pty, os, time
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
    os.execvp("gemini", ["gemini"])
else:
    os.close(slave)
    time.sleep(2) # Wait for startup
    try:
        output = os.read(master, 4096).decode()
        print("--- STARTUP UX ---")
        print(repr(output))
        print("------------------")
        
        # Send a simple prompt
        os.write(master, b"Hello\n")
        time.sleep(3)
        output2 = os.read(master, 4096).decode()
        print("--- RESPONSE UX ---")
        print(repr(output2))
        print("-------------------")
    except Exception as e:
        print(e)
    os.kill(pid, 9)
