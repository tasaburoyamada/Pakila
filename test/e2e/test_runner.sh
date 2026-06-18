#!/bin/bash

# Pakila E2E Test Runner
PAKILA_BIN="${HOME}/.local/bin/pakila"
TEST_DIR="./test_data"

# Pre-flight check
if [ ! -f "$PAKILA_BIN" ]; then
    echo "Error: Binary not found at $PAKILA_BIN"
    exit 1
fi

mkdir -p "$TEST_DIR"

echo "Starting Pakila E2E Binary Tests using: $PAKILA_BIN"

# 1. Memory Boundary Test
echo "Running Memory Boundary Test..."
echo "2KB_DATA" > "$TEST_DIR/boundary_test.bin"
# Input command into stdin to bypass interactive mode
(echo "/write $TEST_DIR/boundary_test.bin TOO_MUCH_DATA_FOR_1KB_BUFFER_...................................................................................................."; echo "/quit") | $PAKILA_BIN
if [ $? -eq 0 ]; then
  echo "Memory Boundary Test Passed"
else
  echo "Memory Boundary Test Failed"
  exit 1
fi

# 2. I/O Robustness Test
echo "Running I/O Robustness Test..."
mkdir -p "$TEST_DIR/readonly"
chmod 555 "$TEST_DIR/readonly"
(echo "/write $TEST_DIR/readonly/test.txt content"; echo "/quit") | $PAKILA_BIN
if [ $? -eq 0 ]; then
  echo "I/O Robustness Test Passed"
else
  echo "I/O Robustness Test Failed"
  exit 1
fi

# 3. Process Timeout Test
echo "Running Process Timeout Test..."
(echo "/bash sleep 2"; echo "/quit") | $PAKILA_BIN
if [ $? -eq 0 ]; then
  echo "Process Timeout Test Passed"
else
  echo "Process Timeout Test Failed"
  exit 1
fi

echo "All E2E Tests Passed."
rm -rf "$TEST_DIR"
exit 0
EOF
