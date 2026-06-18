#!/bin/bash
# pakila/scripts/install.sh

echo "Installing Pakila dependencies..."

# Check for Lean 4
if ! command -v lean &> /dev/null; then
    echo "Lean 4 not found. Please install elan: https://github.com/leanprover/elan"
    exit 1
fi

# Check for required tools
./scripts/check_prereqs.sh
if [ $? -ne 0 ]; then
    exit 1
fi

echo "Dependencies verified. Building Pakila..."
lake build

echo "Pakila installed successfully."
