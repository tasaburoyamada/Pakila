#!/bin/bash
# scenario_runner.sh: Pakila Acceptance Test Runner

PAKILA_BIN="./.lake/build/bin/pakila"
SCENARIO_FILE="test/E2E/scenario_basic.vlog"

if [ ! -f "$PAKILA_BIN" ]; then
  echo "Error: Pakila binary not found."
  exit 1
fi

echo "▶ Running Acceptance Test: $SCENARIO_FILE"

# シナリオの入力をパイプで渡し、期待される出力を検証する
# ここでは簡易的に「/help」を実行して、特定のキーワードが出るか確認する
output=$(echo -e "/help\n/exit" | $PAKILA_BIN)

if echo "$output" | grep -q "ヘルプを表示する"; then
  echo "✔ Acceptance Test Passed: Help menu displayed."
else
  echo "✖ Acceptance Test Failed: Help menu not found."
  echo "Output was:"
  echo "$output"
  exit 1
fi
