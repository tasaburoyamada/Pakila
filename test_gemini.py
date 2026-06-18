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
    os.execvp("gemini", ["gemini", "Hi"])
else:
    os.close(slave)
    time.sleep(3) # Wait for it to settle
    try:
        output = os.read(master, 4096).decode()
        print("---OUTPUT---")
        print(output)
        print("------------")
    except Exception as e:
        print(e)
    os.kill(pid, 9)
