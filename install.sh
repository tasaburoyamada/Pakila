#!/bin/bash
set -e

echo "==============================================="
echo "   PAKILA INSTALLER   "
echo "==============================================="

PAKILA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
BINARY_NAME="pakila"

echo "[1/4] Building Pakila with Lake..."
cd "$PAKILA_ROOT"
lake build pakila

echo "[2/4] Preparing target directory: $BIN_DIR"
mkdir -p "$BIN_DIR"

echo "[3/4] Installing binary..."
cp "$PAKILA_ROOT/.lake/build/bin/pakila" "$BIN_DIR/${BINARY_NAME}_bin"

echo "[4/4] Creating wrapper script..."
printf "#!/bin/bash
export PAKILA_ROOT="$PAKILA_ROOT"
export LD_LIBRARY_PATH="\$PAKILA_ROOT/deps/wasmtime/lib:\$LD_LIBRARY_PATH"
exec "$BIN_DIR/${BINARY_NAME}_bin" "\$@"
" > "$BIN_DIR/$BINARY_NAME"

chmod +x "$BIN_DIR/$BINARY_NAME"

echo "==============================================="
echo "   INSTALLATION COMPLETE   "
echo "==============================================="
