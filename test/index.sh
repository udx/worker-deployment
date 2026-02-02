#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🧪 Running worker-deployment tests..."
echo ""

run_test() {
    local name="$1"
    local file="$2"
    echo "▶ $name"
    "$file"
    echo ""
}

run_test "config" "$SCRIPT_DIR/tests/config.test.sh"
run_test "run" "$SCRIPT_DIR/tests/run.test.sh"
run_test "gen" "$SCRIPT_DIR/tests/gen.test.sh"
run_test "images" "$SCRIPT_DIR/tests/images.test.sh"

echo "✅ All tests completed!"
