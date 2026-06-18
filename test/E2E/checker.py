import sys, select, time
fd = sys.stdin.fileno()
timeout = 2.0
def check():
    ready = select.select([sys.stdin], [], [], timeout)
    if ready[0]:
        return sys.stdin.readline()
    else:
        return None
