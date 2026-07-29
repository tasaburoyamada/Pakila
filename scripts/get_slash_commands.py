import pty, os, time
master, slave = pty.openpty()
pid = os.fork()
if pid == 0:
    os.setsid()
    os.dup2(slave, 0); os.dup2(slave, 1); os.dup2(slave, 2)
    os.close(master); os.close(slave)
    os.execvp("gemini", ["gemini"])
else:
    os.close(slave)
    time.sleep(2)
    os.write(master, b"/help\n")
    time.sleep(2)
    output = os.read(master, 10000).decode()
    print(output)
    os.kill(pid, 9)
