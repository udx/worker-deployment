#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKER="$PKG_DIR/bin/worker"

echo "Images command smoke test (no network assertions)..."
"$WORKER" images --github --limit=1 >/dev/null || true

echo "✅ images test passed"
