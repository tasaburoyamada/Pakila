#!/bin/bash
# pakila/scripts/check_prereqs.sh

REQUIRED_COMMANDS=("scrot" "xdotool" "htmlq" "python3" "curl" "lean" "lake")
MISSING_COMMANDS=()

echo "Checking system prerequisites for pakila..."

for cmd in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    MISSING_COMMANDS+=("$cmd")
  fi
done

if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
  echo "Error: The following required commands are missing:"
  for missing_cmd in "${MISSING_COMMANDS[@]}"; do
    echo "  - $missing_cmd"
  done
  echo "Please install them to run pakila."
  exit 1
else
  echo "All required commands are present."
  exit 0
fi
